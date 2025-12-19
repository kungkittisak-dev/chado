import 'package:analyzer/dart/ast/ast.dart';

/// Low-level AST rewriting utilities.
class AstRewriter {
  /// Replace a node in the source code with new text.
  String rewriteNode(String source, AstNode node, String replacement) {
    return replaceRange(source, node.offset, node.length, replacement);
  }

  /// Remove a node from the source code.
  String removeNode(String source, AstNode node, {bool includeWhitespace = true}) {
    if (!includeWhitespace) {
      return replaceRange(source, node.offset, node.length, '');
    }

    // Try to include surrounding whitespace and newlines
    final extendedRange = _calculateExtendedRange(source, node.offset, node.length);
    return replaceRange(
      source,
      extendedRange.offset,
      extendedRange.length,
      '',
    );
  }

  /// Replace a range in the source code.
  String replaceRange(String source, int offset, int length, String replacement) {
    if (offset < 0 || offset + length > source.length) {
      throw ArgumentError('Invalid range: offset=$offset, length=$length, source length=${source.length}');
    }

    return source.substring(0, offset) + replacement + source.substring(offset + length);
  }

  /// Promote a block (unwrap from parent structure).
  ///
  /// This extracts the contents of a block and places them at the parent level,
  /// preserving proper indentation.
  String promoteBlock(String source, AstNode block, AstNode parent) {
    // Get the content of the block
    String blockContent;

    if (block is Block) {
      // Extract statements from block
      final statements = block.statements;
      if (statements.isEmpty) {
        // Empty block - remove the entire parent
        return removeNode(source, parent);
      }

      final firstOffset = statements.first.offset;
      final lastEnd = statements.last.end;
      blockContent = source.substring(firstOffset, lastEnd);
    } else {
      // Single statement
      blockContent = source.substring(block.offset, block.end);
    }

    // Calculate indentation adjustment
    final parentIndent = _getIndentation(source, parent.offset);
    final blockIndent = _getIndentation(source, block.offset);

    // Adjust indentation if needed
    final adjustedContent = _adjustIndentation(
      blockContent,
      fromLevel: blockIndent,
      toLevel: parentIndent,
    );

    // Replace the entire parent with the promoted content
    return rewriteNode(source, parent, adjustedContent);
  }

  /// Get the indentation level (number of spaces) for a given offset.
  String _getIndentation(String source, int offset) {
    // Find the start of the line
    var lineStart = offset;
    while (lineStart > 0 && source[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Count spaces/tabs at the start of the line
    var indent = '';
    var pos = lineStart;
    while (pos < source.length && (source[pos] == ' ' || source[pos] == '\t')) {
      indent += source[pos];
      pos++;
    }

    return indent;
  }

  /// Adjust indentation of multi-line text.
  String _adjustIndentation(String text, {required String fromLevel, required String toLevel}) {
    final lines = text.split('\n');

    return lines.map((line) {
      // Skip empty lines
      if (line.trim().isEmpty) return line;

      // Remove old indentation if it matches
      var stripped = line;
      if (line.startsWith(fromLevel)) {
        stripped = line.substring(fromLevel.length);
      }

      // Add new indentation
      return toLevel + stripped;
    }).join('\n');
  }

  /// Calculate extended range including surrounding whitespace.
  _Range _calculateExtendedRange(String source, int offset, int length) {
    var start = offset;
    var end = offset + length;

    // Look for newline before
    while (start > 0 && source[start - 1] != '\n') {
      if (source[start - 1] == ' ' || source[start - 1] == '\t') {
        start--;
      } else {
        break;
      }
    }

    // Include the newline if we're at the start of a line
    if (start > 0 && source[start - 1] == '\n') {
      start--;
    }

    // Look for newline after
    while (end < source.length && source[end] != '\n') {
      if (source[end] == ' ' || source[end] == '\t') {
        end++;
      } else {
        break;
      }
    }

    // Include the newline if we're at the end of a line
    if (end < source.length && source[end] == '\n') {
      end++;
    }

    return _Range(start, end - start);
  }

  /// Simplify a boolean expression by replacing a subexpression with a value.
  String simplifyExpression(
    String source,
    Expression expression,
    Expression flagExpression,
    bool flagValue,
  ) {
    if (expression is BinaryExpression) {
      final operator = expression.operator.lexeme;
      final left = expression.leftOperand;
      final right = expression.rightOperand;

      // Check if flag is in left or right
      final flagInLeft = _containsNode(left, flagExpression);

      if (operator == '&&') {
        if (flagValue) {
          // true && other -> other
          final otherSide = flagInLeft ? right : left;
          return rewriteNode(source, expression, source.substring(otherSide.offset, otherSide.end));
        } else {
          // false && other -> false (but this should be handled by dead code elimination)
          return rewriteNode(source, expression, 'false');
        }
      } else if (operator == '||') {
        if (flagValue) {
          // true || other -> true (but this should be handled by dead code elimination)
          return rewriteNode(source, expression, 'true');
        } else {
          // false || other -> other
          final otherSide = flagInLeft ? right : left;
          return rewriteNode(source, expression, source.substring(otherSide.offset, otherSide.end));
        }
      }
    }

    // Can't simplify further
    return source;
  }

  /// Check if a node contains another node.
  bool _containsNode(AstNode container, AstNode node) {
    return container.offset <= node.offset && node.end <= container.end;
  }
}

class _Range {
  final int offset;
  final int length;

  _Range(this.offset, this.length);
}
