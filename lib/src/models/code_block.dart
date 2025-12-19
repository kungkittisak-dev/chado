import 'package:analyzer/dart/ast/ast.dart';

/// Represents a block of code that should be kept or removed during transformation.
class CodeBlock {
  /// The AST node representing this code block.
  final AstNode node;

  /// The character offset where this block starts in the file.
  final int offset;

  /// The length of this block in characters.
  final int length;

  /// The type of this code block.
  final BlockType type;

  /// Whether this block should be kept (true) or removed (false).
  final bool shouldKeep;

  /// The parent node if this block should be promoted.
  final AstNode? parent;

  CodeBlock({
    required this.node,
    required this.offset,
    required this.length,
    required this.type,
    required this.shouldKeep,
    this.parent,
  });

  /// Create a code block marked for removal.
  factory CodeBlock.remove(AstNode node, BlockType type) {
    return CodeBlock(
      node: node,
      offset: node.offset,
      length: node.length,
      type: type,
      shouldKeep: false,
    );
  }

  /// Create a code block marked to be kept/promoted.
  factory CodeBlock.keep(AstNode node, BlockType type, {AstNode? parent}) {
    return CodeBlock(
      node: node,
      offset: node.offset,
      length: node.length,
      type: type,
      shouldKeep: true,
      parent: parent,
    );
  }

  @override
  String toString() {
    return 'CodeBlock('
        'type: $type, '
        'keep: $shouldKeep, '
        'offset: $offset, '
        'length: $length'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeBlock &&
        other.offset == offset &&
        other.length == length &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(offset, length, type);
}

/// Types of code blocks that can be transformed.
enum BlockType {
  /// The 'then' branch of an if statement.
  ifThenBlock,

  /// The 'else' branch of an if statement.
  ifElseBlock,

  /// The 'then' expression of a ternary operator.
  ternaryThen,

  /// The 'else' expression of a ternary operator.
  ternaryElse,

  /// An entire statement that should be removed or kept.
  wholeStatement,

  /// A single expression.
  expression,
}

/// Represents a transformation action to be applied to code.
class TransformationAction {
  /// The type of transformation to apply.
  final ActionType type;

  /// The code block to transform.
  final CodeBlock block;

  /// The replacement text (for REPLACE actions).
  final String? replacement;

  TransformationAction({
    required this.type,
    required this.block,
    this.replacement,
  });

  factory TransformationAction.remove(CodeBlock block) {
    return TransformationAction(type: ActionType.remove, block: block);
  }

  factory TransformationAction.replace(CodeBlock block, String replacement) {
    return TransformationAction(
      type: ActionType.replace,
      block: block,
      replacement: replacement,
    );
  }

  factory TransformationAction.promote(CodeBlock block) {
    return TransformationAction(type: ActionType.promote, block: block);
  }

  @override
  String toString() {
    return 'TransformationAction(type: $type, block: $block)';
  }
}

/// Types of transformation actions.
enum ActionType {
  /// Remove the code block entirely.
  remove,

  /// Replace the code block with different text.
  replace,

  /// Promote the code block to the parent level (unwrap from if statement).
  promote,
}
