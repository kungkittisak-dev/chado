/// Result of transforming a Dart source file.
class TransformationResult {
  /// The original source code before transformation.
  final String originalSource;

  /// The transformed source code after all modifications.
  final String transformedSource;

  /// List of flag names that were removed from this file.
  final List<String> removedFlags;

  /// List of import URIs that were removed from this file.
  final List<String> removedImports;

  /// Number of lines removed during transformation.
  final int linesRemoved;

  /// Whether any changes were made to the file.
  final bool hasChanges;

  /// List of errors or warnings encountered during transformation.
  final List<String> warnings;

  TransformationResult({
    required this.originalSource,
    required this.transformedSource,
    required this.removedFlags,
    required this.removedImports,
    required this.linesRemoved,
    required this.hasChanges,
    this.warnings = const [],
  });

  /// Create a result indicating no changes were made.
  factory TransformationResult.noChanges(String source) {
    return TransformationResult(
      originalSource: source,
      transformedSource: source,
      removedFlags: const [],
      removedImports: const [],
      linesRemoved: 0,
      hasChanges: false,
    );
  }

  /// Create a result with transformations applied.
  factory TransformationResult.withChanges({
    required String originalSource,
    required String transformedSource,
    required List<String> removedFlags,
    required List<String> removedImports,
    List<String> warnings = const [],
  }) {
    final originalLines = originalSource.split('\n').length;
    final transformedLines = transformedSource.split('\n').length;
    final linesRemoved = originalLines - transformedLines;

    return TransformationResult(
      originalSource: originalSource,
      transformedSource: transformedSource,
      removedFlags: removedFlags,
      removedImports: removedImports,
      linesRemoved: linesRemoved,
      hasChanges: originalSource != transformedSource,
      warnings: warnings,
    );
  }

  /// Get a human-readable summary of the transformation.
  String getSummary() {
    if (!hasChanges) {
      return 'No changes made';
    }

    final parts = <String>[];

    if (removedFlags.isNotEmpty) {
      parts.add('${removedFlags.length} flag(s) removed: ${removedFlags.join(", ")}');
    }

    if (removedImports.isNotEmpty) {
      parts.add('${removedImports.length} import(s) removed');
    }

    if (linesRemoved > 0) {
      parts.add('$linesRemoved line(s) removed');
    }

    return parts.join(', ');
  }

  @override
  String toString() {
    return 'TransformationResult(${getSummary()})';
  }
}

/// Aggregate statistics across multiple file transformations.
class AggregateStatistics {
  /// Number of files processed.
  final int filesProcessed;

  /// Number of files that were modified.
  final int filesModified;

  /// Total number of flags removed across all files.
  final int totalFlagsRemoved;

  /// Total number of imports removed across all files.
  final int totalImportsRemoved;

  /// Total number of lines removed across all files.
  final int totalLinesRemoved;

  /// Map of flag names to the number of times they were removed.
  final Map<String, int> flagRemovalCounts;

  /// List of all warnings encountered.
  final List<String> allWarnings;

  AggregateStatistics({
    required this.filesProcessed,
    required this.filesModified,
    required this.totalFlagsRemoved,
    required this.totalImportsRemoved,
    required this.totalLinesRemoved,
    required this.flagRemovalCounts,
    required this.allWarnings,
  });

  /// Create empty statistics.
  factory AggregateStatistics.empty() {
    return AggregateStatistics(
      filesProcessed: 0,
      filesModified: 0,
      totalFlagsRemoved: 0,
      totalImportsRemoved: 0,
      totalLinesRemoved: 0,
      flagRemovalCounts: {},
      allWarnings: [],
    );
  }

  /// Create statistics from a list of transformation results.
  factory AggregateStatistics.fromResults(List<TransformationResult> results) {
    var filesModified = 0;
    var totalFlagsRemoved = 0;
    var totalImportsRemoved = 0;
    var totalLinesRemoved = 0;
    final flagRemovalCounts = <String, int>{};
    final allWarnings = <String>[];

    for (final result in results) {
      if (result.hasChanges) {
        filesModified++;
      }

      totalFlagsRemoved += result.removedFlags.length;
      totalImportsRemoved += result.removedImports.length;
      totalLinesRemoved += result.linesRemoved;

      for (final flag in result.removedFlags) {
        flagRemovalCounts[flag] = (flagRemovalCounts[flag] ?? 0) + 1;
      }

      allWarnings.addAll(result.warnings);
    }

    return AggregateStatistics(
      filesProcessed: results.length,
      filesModified: filesModified,
      totalFlagsRemoved: totalFlagsRemoved,
      totalImportsRemoved: totalImportsRemoved,
      totalLinesRemoved: totalLinesRemoved,
      flagRemovalCounts: flagRemovalCounts,
      allWarnings: allWarnings,
    );
  }

  /// Get a human-readable summary of the statistics.
  String getSummary() {
    final parts = <String>[
      'Processed $filesProcessed file(s)',
      'Modified $filesModified file(s)',
      'Removed $totalFlagsRemoved flag reference(s)',
      'Removed $totalImportsRemoved import(s)',
      'Removed $totalLinesRemoved line(s)',
    ];

    return parts.join('\n');
  }

  @override
  String toString() => getSummary();
}
