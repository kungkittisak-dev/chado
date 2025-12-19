import '../models/flag_reference.dart';
import '../rewriter/ast_rewriter.dart';

/// Removes feature flag definitions from source code.
class FlagDefinitionRemover {
  final AstRewriter _rewriter;

  FlagDefinitionRemover() : _rewriter = AstRewriter();

  /// Remove flag definitions from the source code.
  String removeDefinitions(
    String source,
    List<FlagDefinitionLocation> definitions,
  ) {
    if (definitions.isEmpty) {
      return source;
    }

    var result = source;

    // Sort definitions by offset (descending) to avoid offset shifts
    final sorted = List<FlagDefinitionLocation>.from(definitions)
      ..sort((a, b) => b.offset.compareTo(a.offset));

    for (final definition in sorted) {
      result = _removeDefinition(result, definition);
    }

    return result;
  }

  String _removeDefinition(String source, FlagDefinitionLocation definition) {
    switch (definition.type) {
      case FlagDefinitionType.constant:
      case FlagDefinitionType.variable:
      case FlagDefinitionType.classField:
        // Remove the entire declaration
        return _rewriter.removeNode(source, definition.node, includeWhitespace: true);

      case FlagDefinitionType.enumValue:
        // For enum values, we need to be more careful
        // Remove the enum constant and its trailing comma if present
        return _removeEnumValue(source, definition);
    }
  }

  String _removeEnumValue(String source, FlagDefinitionLocation definition) {
    // Get the enum constant node
    final node = definition.node;
    var start = node.offset;
    var end = node.end;

    // Check for trailing comma
    while (end < source.length && (source[end] == ' ' || source[end] == '\t')) {
      end++;
    }
    if (end < source.length && source[end] == ',') {
      end++; // Include the comma
    }

    // Check for newline
    while (end < source.length && source[end] == '\n') {
      end++;
    }

    return _rewriter.replaceRange(source, start, end - start, '');
  }
}
