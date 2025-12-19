import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// AST visitor that tracks control flow structures (if/else, ternary).
class ControlFlowVisitor extends RecursiveAstVisitor<void> {
  final List<IfStatement> ifStatements = [];
  final List<ConditionalExpression> conditionalExpressions = [];

  @override
  void visitIfStatement(IfStatement node) {
    ifStatements.add(node);
    super.visitIfStatement(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    conditionalExpressions.add(node);
    super.visitConditionalExpression(node);
  }
}

/// Information about a control flow structure.
class ControlFlowInfo {
  final AstNode node;
  final Expression condition;
  final AstNode thenBranch;
  final AstNode? elseBranch;

  ControlFlowInfo({
    required this.node,
    required this.condition,
    required this.thenBranch,
    this.elseBranch,
  });

  factory ControlFlowInfo.fromIfStatement(IfStatement node) {
    return ControlFlowInfo(
      node: node,
      condition: node.expression,
      thenBranch: node.thenStatement,
      elseBranch: node.elseStatement,
    );
  }

  factory ControlFlowInfo.fromConditional(ConditionalExpression node) {
    return ControlFlowInfo(
      node: node,
      condition: node.condition,
      thenBranch: node.thenExpression,
      elseBranch: node.elseExpression,
    );
  }

  bool get hasElse => elseBranch != null;
}
