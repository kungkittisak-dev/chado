import 'package:analyzer/dart/ast/ast.dart';

/// Represents a reference to a feature flag in the source code.
class FlagReference {
  /// The name of the flag being referenced.
  final String flagName;

  /// The resolved boolean value of this flag from the configuration.
  final bool resolvedValue;

  /// The method invocation AST node representing this flag check.
  final MethodInvocation node;

  /// The character offset where this flag reference starts in the file.
  final int offset;

  /// The length of this flag reference in characters.
  final int length;

  /// The parent control flow node (IfStatement or ConditionalExpression) if any.
  final AstNode? parentControlFlow;

  /// Whether this flag reference is negated (e.g., !flag).
  final bool isNegated;

  FlagReference({
    required this.flagName,
    required this.resolvedValue,
    required this.node,
    required this.offset,
    required this.length,
    this.parentControlFlow,
    this.isNegated = false,
  });

  /// The effective boolean value considering negation.
  bool get effectiveValue => isNegated ? !resolvedValue : resolvedValue;

  @override
  String toString() {
    return 'FlagReference('
        'name: $flagName, '
        'value: $resolvedValue, '
        'offset: $offset, '
        'negated: $isNegated'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlagReference &&
        other.flagName == flagName &&
        other.offset == offset &&
        other.length == length;
  }

  @override
  int get hashCode => Object.hash(flagName, offset, length);
}

/// Represents the location of a feature flag definition.
class FlagDefinitionLocation {
  /// The name of the flag being defined.
  final String flagName;

  /// The AST node representing the flag definition.
  final AstNode node;

  /// The character offset where this definition starts.
  final int offset;

  /// The length of this definition in characters.
  final int length;

  /// The type of definition (const, field, enum, etc.).
  final FlagDefinitionType type;

  FlagDefinitionLocation({
    required this.flagName,
    required this.node,
    required this.offset,
    required this.length,
    required this.type,
  });

  @override
  String toString() {
    return 'FlagDefinitionLocation('
        'name: $flagName, '
        'type: $type, '
        'offset: $offset'
        ')';
  }
}

/// Types of feature flag definitions.
enum FlagDefinitionType {
  /// Constant declaration: const myFlag = true;
  constant,

  /// Class field: class Flags { static const myFlag = true; }
  classField,

  /// Enum value: enum FeatureFlags { myFlag }
  enumValue,

  /// Variable declaration: final myFlag = true;
  variable,
}
