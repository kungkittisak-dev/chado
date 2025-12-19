import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// AST visitor that tracks imports and their usage.
class ImportVisitor extends RecursiveAstVisitor<void> {
  final Map<String, ImportUsage> importUsage = {};
  final List<ImportDirective> imports = [];

  @override
  void visitImportDirective(ImportDirective node) {
    imports.add(node);

    final uri = node.uri.stringValue;
    if (uri != null) {
      final prefix = node.prefix?.name;
      final showNames = node.combinators
          .whereType<ShowCombinator>()
          .expand((c) => c.shownNames.map((n) => n.name))
          .toList();
      final hideNames = node.combinators
          .whereType<HideCombinator>()
          .expand((c) => c.hiddenNames.map((n) => n.name))
          .toList();

      importUsage[uri] = ImportUsage(
        directive: node,
        uri: uri,
        prefix: prefix,
        showNames: showNames,
        hideNames: hideNames,
        usageLocations: [],
      );
    }

    super.visitImportDirective(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);

    // Track usage of imported symbols
    final element = node.staticElement;
    if (element != null) {
      final source = element.source;
      if (source != null) {
        final uri = source.uri.toString();

        // Find matching import
        for (final usage in importUsage.values) {
          if (usage.uri == uri || uri.contains(usage.uri)) {
            usage.usageLocations.add(UsageLocation(
              node: node,
              offset: node.offset,
              length: node.length,
              symbolName: node.name,
            ));
          }
        }
      }
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    super.visitPrefixedIdentifier(node);

    // Track usage of prefixed imports (e.g., prefix.symbol)
    final prefix = node.prefix.name;

    for (final usage in importUsage.values) {
      if (usage.prefix == prefix) {
        usage.usageLocations.add(UsageLocation(
          node: node,
          offset: node.offset,
          length: node.length,
          symbolName: node.identifier.name,
        ));
      }
    }
  }
}

/// Information about an import and its usage.
class ImportUsage {
  final ImportDirective directive;
  final String uri;
  final String? prefix;
  final List<String> showNames;
  final List<String> hideNames;
  final List<UsageLocation> usageLocations;

  ImportUsage({
    required this.directive,
    required this.uri,
    this.prefix,
    this.showNames = const [],
    this.hideNames = const [],
    required this.usageLocations,
  });

  /// Whether this import has any usages.
  bool get hasUsages => usageLocations.isNotEmpty;

  /// Number of times this import is used.
  int get usageCount => usageLocations.length;

  /// Whether this import has a show clause.
  bool get hasShowClause => showNames.isNotEmpty;

  /// Whether this import has a hide clause.
  bool get hasHideClause => hideNames.isNotEmpty;
}

/// Location where an imported symbol is used.
class UsageLocation {
  final AstNode node;
  final int offset;
  final int length;
  final String symbolName;

  UsageLocation({
    required this.node,
    required this.offset,
    required this.length,
    required this.symbolName,
  });

  @override
  String toString() {
    return 'UsageLocation(symbol: $symbolName, offset: $offset)';
  }
}
