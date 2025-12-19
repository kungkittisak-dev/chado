import 'package:analyzer/dart/ast/ast.dart';
import '../models/flag_reference.dart';
import '../models/code_block.dart';

/// Analyzes control flow to determine which code branches are dead.
class ControlFlowAnalyzer {
  /// Analyze an if statement containing a flag reference.
  ///
  /// Returns a ControlFlowDecision indicating which branches to keep/remove.
  ControlFlowDecision analyzeIfStatement(
    IfStatement ifStmt,
    FlagReference flag,
  ) {
    final condition = ifStmt.expression;

    // Check if the flag is the entire condition
    if (_isFlagTheWholeCondition(condition, flag)) {
      if (flag.effectiveValue) {
        // Flag is true: keep then, remove else
        return ControlFlowDecision(
          type: DecisionType.keepThenRemoveElse,
          blocksToKeep: [CodeBlock.keep(ifStmt.thenStatement, BlockType.ifThenBlock, parent: ifStmt)],
          blocksToRemove: ifStmt.elseStatement != null
              ? [CodeBlock.remove(ifStmt.elseStatement!, BlockType.ifElseBlock)]
              : [],
          shouldPromote: true,
        );
      } else {
        // Flag is false: remove then, keep else (if exists)
        if (ifStmt.elseStatement != null) {
          return ControlFlowDecision(
            type: DecisionType.removeThenKeepElse,
            blocksToKeep: [CodeBlock.keep(ifStmt.elseStatement!, BlockType.ifElseBlock, parent: ifStmt)],
            blocksToRemove: [CodeBlock.remove(ifStmt.thenStatement, BlockType.ifThenBlock)],
            shouldPromote: true,
          );
        } else {
          // No else block, remove entire if statement
          return ControlFlowDecision(
            type: DecisionType.removeAll,
            blocksToKeep: [],
            blocksToRemove: [CodeBlock.remove(ifStmt, BlockType.wholeStatement)],
            shouldPromote: false,
          );
        }
      }
    }

    // Check if flag is part of a complex condition
    if (condition is BinaryExpression) {
      return _analyzeComplexCondition(ifStmt, condition, flag);
    }

    // Can't analyze, keep everything
    return ControlFlowDecision(
      type: DecisionType.keepBoth,
      blocksToKeep: [],
      blocksToRemove: [],
      shouldPromote: false,
    );
  }

  /// Analyze a conditional expression (ternary) containing a flag.
  ControlFlowDecision analyzeConditionalExpression(
    ConditionalExpression ternary,
    FlagReference flag,
  ) {
    final condition = ternary.condition;

    if (_isFlagTheWholeCondition(condition, flag)) {
      if (flag.effectiveValue) {
        // Flag is true: replace ternary with then expression
        return ControlFlowDecision(
          type: DecisionType.keepThenRemoveElse,
          blocksToKeep: [CodeBlock.keep(ternary.thenExpression, BlockType.ternaryThen, parent: ternary)],
          blocksToRemove: [CodeBlock.remove(ternary.elseExpression, BlockType.ternaryElse)],
          shouldPromote: true,
        );
      } else {
        // Flag is false: replace ternary with else expression
        return ControlFlowDecision(
          type: DecisionType.removeThenKeepElse,
          blocksToKeep: [CodeBlock.keep(ternary.elseExpression, BlockType.ternaryElse, parent: ternary)],
          blocksToRemove: [CodeBlock.remove(ternary.thenExpression, BlockType.ternaryThen)],
          shouldPromote: true,
        );
      }
    }

    // Complex condition, can't simplify
    return ControlFlowDecision(
      type: DecisionType.keepBoth,
      blocksToKeep: [],
      blocksToRemove: [],
      shouldPromote: false,
    );
  }

  /// Check if the flag is the whole condition (possibly with negation).
  bool _isFlagTheWholeCondition(Expression condition, FlagReference flag) {
    // Direct match
    if (condition.offset == flag.node.offset && condition.length == flag.node.length) {
      return true;
    }

    // Check for prefix expression (negation)
    if (condition is PrefixExpression && condition.operator.lexeme == '!') {
      return _isFlagTheWholeCondition(condition.operand, flag);
    }

    return false;
  }

  /// Analyze complex conditions involving && or ||.
  ControlFlowDecision _analyzeComplexCondition(
    IfStatement ifStmt,
    BinaryExpression condition,
    FlagReference flag,
  ) {
    final operator = condition.operator.lexeme;
    final left = condition.leftOperand;
    final right = condition.rightOperand;

    final flagInLeft = _containsFlag(left, flag);
    final flagInRight = _containsFlag(right, flag);

    if (!flagInLeft && !flagInRight) {
      return ControlFlowDecision(
        type: DecisionType.keepBoth,
        blocksToKeep: [],
        blocksToRemove: [],
        shouldPromote: false,
      );
    }

    // Handle && (AND)
    if (operator == '&&') {
      if (flag.effectiveValue) {
        // flag is true: condition becomes just the other side
        // This is a simplification, not a removal
        return ControlFlowDecision(
          type: DecisionType.simplifyCondition,
          blocksToKeep: [],
          blocksToRemove: [],
          shouldPromote: false,
          simplifiedCondition: flagInLeft ? right : left,
        );
      } else {
        // flag is false: entire condition is false, remove whole if
        if (ifStmt.elseStatement != null) {
          return ControlFlowDecision(
            type: DecisionType.removeThenKeepElse,
            blocksToKeep: [CodeBlock.keep(ifStmt.elseStatement!, BlockType.ifElseBlock, parent: ifStmt)],
            blocksToRemove: [CodeBlock.remove(ifStmt.thenStatement, BlockType.ifThenBlock)],
            shouldPromote: true,
          );
        } else {
          return ControlFlowDecision(
            type: DecisionType.removeAll,
            blocksToKeep: [],
            blocksToRemove: [CodeBlock.remove(ifStmt, BlockType.wholeStatement)],
            shouldPromote: false,
          );
        }
      }
    }

    // Handle || (OR)
    if (operator == '||') {
      if (flag.effectiveValue) {
        // flag is true: entire condition is true, keep then block
        return ControlFlowDecision(
          type: DecisionType.keepThenRemoveElse,
          blocksToKeep: [CodeBlock.keep(ifStmt.thenStatement, BlockType.ifThenBlock, parent: ifStmt)],
          blocksToRemove: ifStmt.elseStatement != null
              ? [CodeBlock.remove(ifStmt.elseStatement!, BlockType.ifElseBlock)]
              : [],
          shouldPromote: true,
        );
      } else {
        // flag is false: condition becomes just the other side
        return ControlFlowDecision(
          type: DecisionType.simplifyCondition,
          blocksToKeep: [],
          blocksToRemove: [],
          shouldPromote: false,
          simplifiedCondition: flagInLeft ? right : left,
        );
      }
    }

    // Unknown operator, keep everything
    return ControlFlowDecision(
      type: DecisionType.keepBoth,
      blocksToKeep: [],
      blocksToRemove: [],
      shouldPromote: false,
    );
  }

  /// Check if an expression contains a specific flag reference.
  bool _containsFlag(Expression expr, FlagReference flag) {
    return expr.offset <= flag.offset && flag.offset + flag.length <= expr.end;
  }
}

/// Decision about how to transform control flow.
class ControlFlowDecision {
  final DecisionType type;
  final List<CodeBlock> blocksToKeep;
  final List<CodeBlock> blocksToRemove;
  final bool shouldPromote;
  final Expression? simplifiedCondition;

  ControlFlowDecision({
    required this.type,
    required this.blocksToKeep,
    required this.blocksToRemove,
    required this.shouldPromote,
    this.simplifiedCondition,
  });

  @override
  String toString() {
    return 'ControlFlowDecision('
        'type: $type, '
        'promote: $shouldPromote, '
        'keep: ${blocksToKeep.length}, '
        'remove: ${blocksToRemove.length}'
        ')';
  }
}

/// Types of control flow decisions.
enum DecisionType {
  /// Keep then block, remove else block.
  keepThenRemoveElse,

  /// Remove then block, keep else block.
  removeThenKeepElse,

  /// Keep both blocks (can't simplify).
  keepBoth,

  /// Remove entire if statement.
  removeAll,

  /// Simplify the condition (partial evaluation).
  simplifyCondition,
}
