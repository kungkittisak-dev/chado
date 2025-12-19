import 'dart:io';
import 'package:dart_style/dart_style.dart';
import '../config/flag_config.dart';
import '../analyzer/dart_file_analyzer.dart';
import '../analyzer/import_analyzer.dart';
import '../models/transformation_result.dart';
import 'dead_code_eliminator.dart';
import 'import_cleaner.dart';
import 'flag_definition_remover.dart';

/// Coordinates all code transformations for a file.
class CodeTransformer {
  final FlagConfig config;
  final DartFormatter _formatter;
  final DeadCodeEliminator _deadCodeEliminator;
  final ImportCleaner _importCleaner;
  final FlagDefinitionRemover _flagDefinitionRemover;
  final ImportAnalyzer _importAnalyzer;

  CodeTransformer(this.config)
      : _formatter = DartFormatter(),
        _deadCodeEliminator = DeadCodeEliminator(),
        _importCleaner = ImportCleaner(),
        _flagDefinitionRemover = FlagDefinitionRemover(),
        _importAnalyzer = ImportAnalyzer();

  /// Transform a Dart file by removing feature flags and dead code.
  Future<TransformationResult> transform(File file) async {
    // Analyze the file
    final analyzer = DartFileAnalyzer(config);
    final analysis = await analyzer.analyze(file);

    // Check for parse errors
    if (analysis.hasErrors) {
      return TransformationResult.withChanges(
        originalSource: analysis.source,
        transformedSource: analysis.source,
        removedFlags: [],
        removedImports: [],
        warnings: analysis.errors,
      );
    }

    // Check if there are any flags to process
    if (!analysis.hasFlagReferences && !analysis.hasFlagDefinitions) {
      return TransformationResult.noChanges(analysis.source);
    }

    var transformedSource = analysis.source;
    final removedFlagNames = <String>{};
    final warnings = <String>[];

    try {
      // Step 1: Eliminate dead code branches
      if (analysis.hasFlagReferences) {
        transformedSource = _deadCodeEliminator.eliminateDeadCode(
          transformedSource,
          analysis.flagReferences,
        );

        removedFlagNames.addAll(
          analysis.flagReferences.map((ref) => ref.flagName),
        );
      }

      // Step 2: Remove flag definitions
      if (analysis.hasFlagDefinitions) {
        transformedSource = _flagDefinitionRemover.removeDefinitions(
          transformedSource,
          analysis.flagDefinitions,
        );

        removedFlagNames.addAll(
          analysis.flagDefinitions.map((def) => def.flagName),
        );
      }

      // Step 3: Clean up unused imports
      // Note: We need to re-analyze imports after transformation
      // For now, we'll use a simplified approach
      final unusedImports = _importAnalyzer.findFlagServiceImports(
        analysis.imports,
        config.patterns?.classes ?? [],
      );

      final removedImportUris = <String>[];
      if (unusedImports.isNotEmpty) {
        transformedSource = _importCleaner.cleanImports(
          transformedSource,
          unusedImports,
        );

        removedImportUris.addAll(
          unusedImports.map((imp) => imp.uri.stringValue ?? 'unknown'),
        );
      }

      // Step 4: Format the output (if configured)
      if (config.settings?.formatOutput ?? true) {
        try {
          transformedSource = _formatter.format(transformedSource);
        } catch (e) {
          warnings.add('Failed to format code: $e');
          // Continue with unformatted code
        }
      }

      return TransformationResult.withChanges(
        originalSource: analysis.source,
        transformedSource: transformedSource,
        removedFlags: removedFlagNames.toList(),
        removedImports: removedImportUris,
        warnings: warnings,
      );
    } catch (e) {
      // If transformation fails, return the original source with error
      warnings.add('Transformation failed: $e');
      return TransformationResult.withChanges(
        originalSource: analysis.source,
        transformedSource: analysis.source,
        removedFlags: [],
        removedImports: [],
        warnings: warnings,
      );
    }
  }
}
