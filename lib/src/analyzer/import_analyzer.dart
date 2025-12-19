import 'package:analyzer/dart/ast/ast.dart';
import '../visitor/import_visitor.dart';
import '../models/code_block.dart';

/// Analyzes imports and determines which are unused after code transformation.
class ImportAnalyzer {
  /// Analyze imports in a compilation unit.
  Map<String, ImportUsage> analyzeImports(CompilationUnit unit) {
    final visitor = ImportVisitor();
    unit.visitChildren(visitor);
    return visitor.importUsage;
  }

  /// Find imports that will become unused after removing specified code blocks.
  List<ImportDirective> findUnusedAfterTransform(
    Map<String, ImportUsage> imports,
    List<CodeBlock> blocksToRemove,
  ) {
    final unusedImports = <ImportDirective>[];

    for (final usage in imports.values) {
      // Check if all usages of this import are in code blocks to be removed
      final remainingUsages = usage.usageLocations.where((location) {
        return !_isLocationInRemovedBlocks(location, blocksToRemove);
      }).toList();

      if (remainingUsages.isEmpty) {
        // This import will have no remaining usages after transformation
        unusedImports.add(usage.directive);
      }
    }

    return unusedImports;
  }

  /// Check if a usage location is within any of the blocks to be removed.
  bool _isLocationInRemovedBlocks(
    UsageLocation location,
    List<CodeBlock> blocksToRemove,
  ) {
    for (final block in blocksToRemove) {
      if (_isWithinRange(location.offset, location.length, block.offset, block.length)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a range is within another range.
  bool _isWithinRange(int offset, int length, int blockOffset, int blockLength) {
    final end = offset + length;
    final blockEnd = blockOffset + blockLength;
    return blockOffset <= offset && end <= blockEnd;
  }

  /// Get imports related to flag services that might be removed.
  List<ImportDirective> findFlagServiceImports(
    Map<String, ImportUsage> imports,
    List<String> flagServicePatterns,
  ) {
    final flagImports = <ImportDirective>[];

    for (final usage in imports.values) {
      // Check if this import URI contains any flag service pattern
      for (final pattern in flagServicePatterns) {
        if (usage.uri.contains(pattern) ||
            usage.uri.contains('flag') ||
            usage.uri.contains('feature')) {
          flagImports.add(usage.directive);
          break;
        }
      }
    }

    return flagImports;
  }
}
