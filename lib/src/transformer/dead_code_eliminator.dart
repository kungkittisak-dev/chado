import 'package:analyzer/dart/ast/ast.dart';
import '../models/flag_reference.dart';
import '../analyzer/control_flow_analyzer.dart';
import '../rewriter/ast_rewriter.dart';

/// Eliminates dead code branches based on feature flag values.
class DeadCodeEliminator {
  final ControlFlowAnalyzer _analyzer;
  final AstRewriter _rewriter;

  DeadCodeEliminator()
      : _analyzer = ControlFlowAnalyzer(),
        _rewriter = AstRewriter();

  /// Eliminate dead code for all flag references in the source.
  ///
  /// Returns the transformed source code.
  String eliminateDeadCode(
    String source,
    List<FlagReference> flagReferences,
  ) {
    var result = source;

    // Group flags by their parent control flow node
    final flagsByControlFlow = <AstNode?, List<FlagReference>>{};
    for (final flag in flagReferences) {
      final parent = flag.parentControlFlow;
      flagsByControlFlow.putIfAbsent(parent, () => []).add(flag);
    }

    // Collect all transformations
    final transformations = <_Transformation>[];

    for (final entry in flagsByControlFlow.entries) {
      final parentNode = entry.key;
      final flags = entry.value;

      if (parentNode == null) {
        // No control flow parent, just replace flag call with boolean literal
        for (final flag in flags) {
          transformations.add(_Transformation(
            offset: flag.node.offset,
            length: flag.node.length,
            replacement: flag.effectiveValue.toString(),
            priority: 0,
          ));
        }
        continue;
      }

      // Analyze control flow
      if (parentNode is IfStatement) {
        final decision = _analyzer.analyzeIfStatement(parentNode, flags.first);
        transformations.addAll(_createTransformationsFromDecision(
          source,
          parentNode,
          decision,
        ));
      } else if (parentNode is ConditionalExpression) {
        final decision = _analyzer.analyzeConditionalExpression(parentNode, flags.first);
        transformations.addAll(_createTransformationsFromDecision(
          source,
          parentNode,
          decision,
        ));
      }
    }

    // Sort transformations by offset (descending) to avoid offset shifts
    transformations.sort((a, b) => b.offset.compareTo(a.offset));

    // Apply transformations
    for (final transformation in transformations) {
      result = _rewriter.replaceRange(
        result,
        transformation.offset,
        transformation.length,
        transformation.replacement,
      );
    }

    return result;
  }

  /// Create transformations from a control flow decision.
  List<_Transformation> _createTransformationsFromDecision(
    String source,
    AstNode node,
    ControlFlowDecision decision,
  ) {
    final transformations = <_Transformation>[];

    switch (decision.type) {
      case DecisionType.keepThenRemoveElse:
      case DecisionType.removeThenKeepElse:
        if (decision.shouldPromote && decision.blocksToKeep.isNotEmpty) {
          // Promote the kept block
          final blockToKeep = decision.blocksToKeep.first;
          final promoted = _rewriter.promoteBlock(
            source,
            blockToKeep.node,
            blockToKeep.parent ?? node,
          );

          transformations.add(_Transformation(
            offset: node.offset,
            length: node.length,
            replacement: promoted.substring(node.offset, node.offset + node.length),
            priority: 1,
          ));
        }
        break;

      case DecisionType.removeAll:
        // Remove the entire control flow statement
        transformations.add(_Transformation(
          offset: node.offset,
          length: node.length,
          replacement: '',
          priority: 1,
        ));
        break;

      case DecisionType.simplifyCondition:
        if (decision.simplifiedCondition != null) {
          // Replace the condition with the simplified version
          if (node is IfStatement) {
            final condition = node.expression;
            final simplified = source.substring(
              decision.simplifiedCondition!.offset,
              decision.simplifiedCondition!.end,
            );

            transformations.add(_Transformation(
              offset: condition.offset,
              length: condition.length,
              replacement: simplified,
              priority: 0,
            ));
          }
        }
        break;

      case DecisionType.keepBoth:
        // No transformation needed
        break;
    }

    return transformations;
  }
}

/// Represents a single transformation to apply to the source code.
class _Transformation {
  final int offset;
  final int length;
  final String replacement;
  final int priority; // Higher priority transformations are applied first

  _Transformation({
    required this.offset,
    required this.length,
    required this.replacement,
    required this.priority,
  });
}
