import 'package:args/args.dart';

/// Options for the Chado CLI tool.
class ChadoOptions {
  /// Path to the configuration file (YAML or JSON).
  final String configPath;

  /// Target file or directory to process.
  final String targetPath;

  /// Whether to perform a dry run (no files modified).
  final bool dryRun;

  /// Whether to output verbose logging.
  final bool verbose;

  /// Patterns to exclude from processing.
  final List<String> excludePatterns;

  ChadoOptions({
    required this.configPath,
    required this.targetPath,
    this.dryRun = false,
    this.verbose = false,
    this.excludePatterns = const [],
  });

  /// Parse options from command-line arguments.
  static ChadoOptions parse(List<String> arguments) {
    final parser = _createArgParser();

    try {
      final results = parser.parse(arguments);

      if (results['help'] as bool) {
        _printUsage(parser);
        throw ChadoOptionsException('Help requested', exitCode: 0);
      }

      // Validate required options
      if (!results.wasParsed('config')) {
        throw ChadoOptionsException('Missing required option: --config');
      }

      if (!results.wasParsed('target')) {
        throw ChadoOptionsException('Missing required option: --target');
      }

      // Parse exclude patterns
      final excludePatterns = results['exclude'] as String?;
      final excludeList = excludePatterns != null
          ? excludePatterns.split(',').map((p) => p.trim()).toList()
          : <String>[];

      return ChadoOptions(
        configPath: results['config'] as String,
        targetPath: results['target'] as String,
        dryRun: results['dry-run'] as bool,
        verbose: results['verbose'] as bool,
        excludePatterns: excludeList,
      );
    } on FormatException catch (e) {
      throw ChadoOptionsException('Invalid arguments: ${e.message}');
    }
  }

  static ArgParser _createArgParser() {
    return ArgParser()
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to the configuration file (YAML or JSON)',
        valueHelp: 'path/to/config.yaml',
      )
      ..addOption(
        'target',
        abbr: 't',
        help: 'Target file or directory to process',
        valueHelp: 'lib/',
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Preview changes without modifying files',
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show verbose output',
        negatable: false,
      )
      ..addOption(
        'exclude',
        abbr: 'e',
        help: 'Comma-separated list of patterns to exclude',
        valueHelp: '**/*.g.dart,**/*.freezed.dart',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show this help message',
        negatable: false,
      );
  }

  static void _printUsage(ArgParser parser) {
    print('Chado - Feature Flag Removal Tool');
    print('');
    print('Usage: chado [options]');
    print('');
    print('Options:');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  chado --config=flags.yaml --target=lib/');
    print('  chado -c flags.yaml -t lib/ --dry-run');
    print('  chado -c flags.yaml -t lib/ --exclude="**/*.g.dart"');
  }

  @override
  String toString() {
    return 'ChadoOptions('
        'config: $configPath, '
        'target: $targetPath, '
        'dryRun: $dryRun, '
        'verbose: $verbose'
        ')';
  }
}

/// Exception thrown when parsing options fails.
class ChadoOptionsException implements Exception {
  final String message;
  final int exitCode;

  ChadoOptionsException(this.message, {this.exitCode = 1});

  @override
  String toString() => message;
}
