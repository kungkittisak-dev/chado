import 'dart:io';
import '../config/config_loader.dart';
import '../config/flag_config.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../transformer/code_transformer.dart';
import '../models/transformation_result.dart';
import 'options.dart';

/// Main command runner for the Chado CLI tool.
class ChadoCommandRunner {
  /// Run the Chado tool with the given arguments.
  ///
  /// Returns exit code: 0 for success, 1 for error.
  Future<int> run(List<String> arguments) async {
    try {
      // Parse options
      final options = ChadoOptions.parse(arguments);

      // Initialize logger
      ChadoLogger.initialize(verbose: options.verbose);

      ChadoLogger.info('Chado - Feature Flag Removal Tool');
      ChadoLogger.debug('Options: $options');

      // Load configuration
      ChadoLogger.progress('Loading configuration from ${options.configPath}');
      final configResult = await _loadConfig(options.configPath);
      final config = configResult.config;
      final configWarnings = configResult.warnings;

      ChadoLogger.info('Loaded ${config.flags.length} flag(s) from configuration');
      for (final entry in config.flags.entries) {
        final flag = entry.value;
        final metadata = [
          if (flag.owner != null) 'owner: ${flag.owner}',
          if (flag.expire != null) 'expires: ${flag.expire!.toIso8601String().split('T')[0]}',
        ].join(', ');

        ChadoLogger.debug('  ${entry.key}: ${entry.value.value}${metadata.isNotEmpty ? ' ($metadata)' : ''}');
      }

      // Show configuration warnings (e.g., expired flags)
      if (configWarnings.isNotEmpty) {
        ChadoLogger.warning('\nConfiguration warnings:');
        for (final warning in configWarnings) {
          ChadoLogger.warning('  $warning');
        }
      }

      // Find Dart files to process
      ChadoLogger.progress('Finding Dart files in ${options.targetPath}');
      final files = await FileUtils.findDartFiles(
        options.targetPath,
        excludePatterns: options.excludePatterns,
      );

      if (files.isEmpty) {
        ChadoLogger.warning('No Dart files found in ${options.targetPath}');
        return 0;
      }

      ChadoLogger.info('Found ${files.length} Dart file(s) to process');

      // Process files
      final results = await _processFiles(files, config, options);

      // Generate statistics
      final stats = AggregateStatistics.fromResults(results);

      // Print summary
      _printSummary(stats, options.dryRun);

      // Print warnings if any
      if (stats.allWarnings.isNotEmpty) {
        ChadoLogger.warning('\nWarnings:');
        for (final warning in stats.allWarnings) {
          ChadoLogger.warning('  $warning');
        }
      }

      return 0;
    } on ChadoOptionsException catch (e) {
      if (e.exitCode != 0) {
        ChadoLogger.error(e.message);
      }
      return e.exitCode;
    } catch (e, stackTrace) {
      ChadoLogger.error('Fatal error: $e', e, stackTrace);
      return 1;
    }
  }

  Future<_ConfigLoadResult> _loadConfig(String configPath) async {
    try {
      final loader = ConfigLoader();
      final config = await loader.load(configPath);
      final warnings = loader.validate(config);
      return _ConfigLoadResult(config, warnings);
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  Future<List<TransformationResult>> _processFiles(
    List<File> files,
    FlagConfig config,
    ChadoOptions options,
  ) async {
    final results = <TransformationResult>[];
    final transformer = CodeTransformer(config);

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = FileUtils.getRelativePath(
        options.targetPath,
        file.path,
      );

      ChadoLogger.progress('[${i + 1}/${files.length}] Processing $relativePath');

      try {
        final result = await transformer.transform(file);
        results.add(result);

        if (result.hasChanges) {
          ChadoLogger.debug('  ${result.getSummary()}');

          if (!options.dryRun) {
            // Write the transformed code back to the file
            await FileUtils.writeFile(file, result.transformedSource);
            ChadoLogger.success('  Modified $relativePath');
          } else {
            ChadoLogger.info('  Would modify $relativePath (dry-run)');
          }
        } else {
          ChadoLogger.debug('  No changes needed');
        }
      } catch (e) {
        ChadoLogger.error('  Error processing $relativePath: $e');
        results.add(TransformationResult.noChanges(''));
      }
    }

    return results;
  }

  void _printSummary(AggregateStatistics stats, bool dryRun) {
    ChadoLogger.info('\n' + ('=' * 50));
    ChadoLogger.info('Summary:');
    ChadoLogger.info(('=' * 50));

    if (dryRun) {
      ChadoLogger.info('DRY RUN - No files were modified');
    }

    ChadoLogger.info(stats.getSummary());

    if (stats.flagRemovalCounts.isNotEmpty) {
      ChadoLogger.info('\nFlags removed:');
      for (final entry in stats.flagRemovalCounts.entries) {
        ChadoLogger.info('  ${entry.key}: ${entry.value} occurrence(s)');
      }
    }

    if (stats.filesModified > 0) {
      if (dryRun) {
        ChadoLogger.success('\n${stats.filesModified} file(s) would be modified');
      } else {
        ChadoLogger.success('\n${stats.filesModified} file(s) successfully modified');
      }
    } else {
      ChadoLogger.info('\nNo files needed modification');
    }
  }
}

/// Result of loading and validating configuration.
class _ConfigLoadResult {
  final FlagConfig config;
  final List<String> warnings;

  _ConfigLoadResult(this.config, this.warnings);
}
