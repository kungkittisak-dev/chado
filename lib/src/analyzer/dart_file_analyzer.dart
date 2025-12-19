import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../config/flag_config.dart';
import '../models/flag_reference.dart';
import '../visitor/import_visitor.dart';
import 'flag_detector.dart';
import 'import_analyzer.dart';

/// Coordinates analysis of a Dart file to find flag usages and imports.
class DartFileAnalyzer {
  final FlagConfig config;
  late final FlagDetector _flagDetector;
  late final ImportAnalyzer _importAnalyzer;

  DartFileAnalyzer(this.config) {
    _flagDetector = FlagDetector(config);
    _importAnalyzer = ImportAnalyzer();
  }

  /// Analyze a Dart file and return the analysis result.
  Future<FileAnalysisResult> analyze(File file) async {
    final source = await file.readAsString();
    final parseResult = parseString(content: source, throwIfDiagnostics: false);

    if (parseResult.errors.isNotEmpty) {
      // Log parse errors but continue
      final errorMessages = parseResult.errors
          .map((e) => 'Parse error at line ${e.offset}: ${e.message}')
          .toList();

      return FileAnalysisResult.withErrors(
        file: file,
        source: source,
        errors: errorMessages,
      );
    }

    final unit = parseResult.unit;

    // Detect flag usages
    final flagReferences = _flagDetector.detectFlags(unit);

    // Detect flag definitions
    final flagDefinitions = _flagDetector.detectFlagDefinitions(unit);

    // Analyze imports
    final imports = _importAnalyzer.analyzeImports(unit);

    return FileAnalysisResult(
      file: file,
      source: source,
      compilationUnit: unit,
      flagReferences: flagReferences,
      flagDefinitions: flagDefinitions,
      imports: imports,
    );
  }
}

/// Result of analyzing a Dart file.
class FileAnalysisResult {
  final File file;
  final String source;
  final CompilationUnit? compilationUnit;
  final List<FlagReference> flagReferences;
  final List<FlagDefinitionLocation> flagDefinitions;
  final Map<String, ImportUsage> imports;
  final List<String> errors;

  FileAnalysisResult({
    required this.file,
    required this.source,
    this.compilationUnit,
    this.flagReferences = const [],
    this.flagDefinitions = const [],
    this.imports = const {},
    this.errors = const [],
  });

  factory FileAnalysisResult.withErrors({
    required File file,
    required String source,
    required List<String> errors,
  }) {
    return FileAnalysisResult(
      file: file,
      source: source,
      errors: errors,
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get hasFlagReferences => flagReferences.isNotEmpty;
  bool get hasFlagDefinitions => flagDefinitions.isNotEmpty;

  @override
  String toString() {
    return 'FileAnalysisResult('
        'file: ${file.path}, '
        'flags: ${flagReferences.length}, '
        'definitions: ${flagDefinitions.length}, '
        'imports: ${imports.length}, '
        'errors: ${errors.length}'
        ')';
  }
}
