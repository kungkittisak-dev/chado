import 'package:analyzer/dart/ast/ast.dart';
import '../rewriter/ast_rewriter.dart';

/// Cleans up unused imports from source code.
class ImportCleaner {
  final AstRewriter _rewriter;

  ImportCleaner() : _rewriter = AstRewriter();

  /// Remove unused import directives from the source code.
  String cleanImports(String source, List<ImportDirective> unusedImports) {
    if (unusedImports.isEmpty) {
      return source;
    }

    var result = source;

    // Sort imports by offset (descending) to avoid offset shifts
    final sorted = List<ImportDirective>.from(unusedImports)
      ..sort((a, b) => b.offset.compareTo(a.offset));

    for (final import in sorted) {
      result = _rewriter.removeNode(result, import, includeWhitespace: true);
    }

    return result;
  }

  /// Update a show clause by removing specific symbols.
  ///
  /// If all symbols are removed, the entire import is removed.
  String updateShowClause(
    String source,
    ImportDirective import,
    List<String> symbolsToRemove,
  ) {
    // Find the show combinator
    final showCombinator = import.combinators
        .whereType<ShowCombinator>()
        .firstOrNull;

    if (showCombinator == null) {
      // No show clause, can't update
      return source;
    }

    final shownNames = showCombinator.shownNames.map((n) => n.name).toList();
    final remaining = shownNames.where((name) => !symbolsToRemove.contains(name)).toList();

    if (remaining.isEmpty) {
      // All symbols removed, remove entire import
      return _rewriter.removeNode(source, import);
    }

    if (remaining.length == shownNames.length) {
      // No changes needed
      return source;
    }

    // Rebuild the show clause
    final newShowClause = 'show ${remaining.join(', ')}';
    return _rewriter.rewriteNode(source, showCombinator, newShowClause);
  }

  /// Remove duplicate imports (keep first occurrence).
  String removeDuplicateImports(String source, List<ImportDirective> imports) {
    final seen = <String>{};
    final duplicates = <ImportDirective>[];

    for (final import in imports) {
      final uri = import.uri.stringValue;
      if (uri != null) {
        if (seen.contains(uri)) {
          duplicates.add(import);
        } else {
          seen.add(uri);
        }
      }
    }

    return cleanImports(source, duplicates);
  }
}
