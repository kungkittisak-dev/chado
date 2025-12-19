import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../config/flag_config.dart';
import '../models/flag_reference.dart';

/// AST visitor that finds all feature flag method invocations in the code.
class FlagUsageVisitor extends RecursiveAstVisitor<void> {
  final FlagConfig config;
  final List<FlagReference> flagReferences = [];

  FlagUsageVisitor(this.config);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    // Check if this method invocation matches any configured pattern
    if (_matchesPattern(node)) {
      final flagName = _extractFlagName(node);
      if (flagName != null) {
        final flagDef = _resolveFlagDefinition(flagName);
        if (flagDef != null) {
          // Check if this flag call is negated
          final isNegated = _isNegated(node);

          // Find parent control flow node
          final parentControlFlow = _findParentControlFlow(node);

          final reference = FlagReference(
            flagName: flagName,
            resolvedValue: flagDef.value,
            node: node,
            offset: node.offset,
            length: node.length,
            parentControlFlow: parentControlFlow,
            isNegated: isNegated,
          );

          flagReferences.add(reference);
        }
      }
    }
  }

  /// Check if this method invocation matches any configured pattern.
  bool _matchesPattern(MethodInvocation node) {
    final patterns = config.patterns?.methods ?? [];
    if (patterns.isEmpty) {
      // Default patterns if none configured
      return _matchesDefaultPattern(node);
    }

    for (final pattern in patterns) {
      if (_matchesSinglePattern(node, pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Check if method invocation matches a single pattern.
  bool _matchesSinglePattern(MethodInvocation node, String pattern) {
    // Pattern: "ClassName.methodName"
    if (pattern.contains('.')) {
      final parts = pattern.split('.');
      final className = parts[0];
      final methodName = parts[1];

      // Match method name
      if (node.methodName.name != methodName) {
        return false;
      }

      // Wildcard for class name
      if (className == '*') {
        return true;
      }

      // Check target (for static calls or instance calls)
      if (node.target is SimpleIdentifier) {
        final target = node.target as SimpleIdentifier;
        return target.name == className;
      }

      // Check for instance method on typed object
      final targetType = node.target?.staticType;
      if (targetType != null) {
        final element = targetType.element;
        return element?.name == className;
      }

      return false;
    }

    // Pattern: "methodName" (any receiver)
    return node.methodName.name == pattern;
  }

  /// Check against default patterns.
  bool _matchesDefaultPattern(MethodInvocation node) {
    final methodName = node.methodName.name;
    return methodName == 'isEnabled' ||
        methodName == 'check' ||
        methodName == 'isFeatureEnabled';
  }

  /// Extract the flag name from the method invocation arguments.
  String? _extractFlagName(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.isEmpty) return null;

    final firstArg = args.first;

    // Handle string literal
    if (firstArg is SimpleStringLiteral) {
      return firstArg.value;
    }

    // Handle string interpolation (take the literal parts if simple)
    if (firstArg is StringInterpolation) {
      // For now, only handle simple case with no interpolation
      if (firstArg.elements.length == 1 &&
          firstArg.elements.first is InterpolationString) {
        return (firstArg.elements.first as InterpolationString).value;
      }
    }

    // Handle const string variable reference
    if (firstArg is SimpleIdentifier) {
      final element = firstArg.staticElement;
      if (element != null) {
        // Try to resolve the const value
        // This is a simplified version - full implementation would need
        // to trace the const value through the AST
        return firstArg.name;
      }
    }

    return null;
  }

  /// Resolve the flag definition from config by name or alias.
  FlagDefinition? _resolveFlagDefinition(String flagName) {
    // Direct match
    if (config.flags.containsKey(flagName)) {
      return config.flags[flagName];
    }

    // Check aliases
    for (final flagDef in config.flags.values) {
      if (flagDef.matches(flagName)) {
        return flagDef;
      }
    }

    return null;
  }

  /// Check if this flag call is negated (wrapped in ! operator).
  bool _isNegated(MethodInvocation node) {
    var parent = node.parent;

    // Check for prefix expression with ! operator
    while (parent != null) {
      if (parent is PrefixExpression && parent.operator.lexeme == '!') {
        // Make sure this is directly negating our node, not something else
        if (parent.operand == node) {
          return true;
        }
      }

      // Stop at control flow boundaries
      if (parent is IfStatement ||
          parent is ConditionalExpression ||
          parent is WhileStatement ||
          parent is ForStatement) {
        break;
      }

      parent = parent.parent;
    }

    return false;
  }

  /// Find the parent control flow node (IfStatement or ConditionalExpression).
  AstNode? _findParentControlFlow(AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is IfStatement || parent is ConditionalExpression) {
        // Make sure this node is in the condition, not in the body
        if (parent is IfStatement && _isInCondition(node, parent.expression)) {
          return parent;
        }
        if (parent is ConditionalExpression &&
            _isInCondition(node, parent.condition)) {
          return parent;
        }
      }

      parent = parent.parent;
    }

    return null;
  }

  /// Check if a node is contained within an expression.
  bool _isInCondition(AstNode node, Expression condition) {
    return condition.offset <= node.offset &&
        node.end <= condition.end;
  }
}
