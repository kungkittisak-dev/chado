import 'package:analyzer/dart/ast/ast.dart';
import '../config/flag_config.dart';
import '../models/flag_reference.dart';
import '../visitor/flag_usage_visitor.dart';

/// Detects feature flag usages in AST.
class FlagDetector {
  final FlagConfig config;
  FlagUsageVisitor? _cachedVisitor;
  CompilationUnit? _cachedUnit;

  FlagDetector(this.config);

  /// Get or create the visitor for a compilation unit.
  /// This ensures we only visit the AST once and reuse the results.
  FlagUsageVisitor _getVisitor(CompilationUnit unit) {
    if (_cachedUnit != unit || _cachedVisitor == null) {
      _cachedVisitor = FlagUsageVisitor(config);
      unit.visitChildren(_cachedVisitor!);
      _cachedUnit = unit;
    }
    return _cachedVisitor!;
  }

  /// Detect all feature flag references in a compilation unit.
  List<FlagReference> detectFlags(CompilationUnit unit) {
    final visitor = _getVisitor(unit);
    return visitor.flagReferences;
  }

  /// Detect flag definitions in a compilation unit.
  ///
  /// This finds places where flags are defined (const declarations, fields, etc.)
  /// that should be removed if configured to do so.
  List<FlagDefinitionLocation> detectFlagDefinitions(CompilationUnit unit) {
    final definitions = <FlagDefinitionLocation>[];
    final visitor = _getVisitor(unit);

    // Include variable declarations that hold flag values
    for (final varInfo in visitor.flagVariables.entries) {
      final varName = varInfo.key;
      final flagInfo = varInfo.value;
      final flagDef = config.flags[flagInfo.flagName];

      // Only remove if configured to do so
      if (flagDef != null && flagDef.removeDefinition) {
        // Find the complete statement to remove (VariableDeclarationStatement)
        // variableNode.parent is VariableDeclarationList
        // variableNode.parent.parent is VariableDeclarationStatement
        final statementNode = flagInfo.variableNode.parent?.parent ??
                              flagInfo.variableNode.parent ??
                              flagInfo.variableNode;

        // Validate that the offset and length are within bounds
        // This prevents errors if the AST nodes have invalid ranges
        if (statementNode.offset >= 0 && statementNode.length > 0) {
          definitions.add(FlagDefinitionLocation(
            flagName: varName,
            node: statementNode,
            offset: statementNode.offset,
            length: statementNode.length,
            type: FlagDefinitionType.variable,
          ));
        }
      }
    }

    // Find top-level constants
    for (final declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          final name = variable.name.lexeme;
          if (_shouldRemoveFlagDefinition(name)) {
            definitions.add(FlagDefinitionLocation(
              flagName: name,
              node: declaration,
              offset: declaration.offset,
              length: declaration.length,
              type: FlagDefinitionType.constant,
            ));
          }
        }
      }

      // Find class fields
      if (declaration is ClassDeclaration) {
        for (final member in declaration.members) {
          if (member is FieldDeclaration) {
            for (final variable in member.fields.variables) {
              final name = variable.name.lexeme;
              if (_shouldRemoveFlagDefinition(name)) {
                definitions.add(FlagDefinitionLocation(
                  flagName: name,
                  node: member,
                  offset: member.offset,
                  length: member.length,
                  type: FlagDefinitionType.classField,
                ));
              }
            }
          }
        }
      }

      // Find enum values
      if (declaration is EnumDeclaration) {
        for (final constant in declaration.constants) {
          final name = constant.name.lexeme;
          if (_shouldRemoveFlagDefinition(name)) {
            definitions.add(FlagDefinitionLocation(
              flagName: name,
              node: constant,
              offset: constant.offset,
              length: constant.length,
              type: FlagDefinitionType.enumValue,
            ));
          }
        }
      }
    }

    return definitions;
  }

  /// Check if a flag definition should be removed based on config.
  bool _shouldRemoveFlagDefinition(String name) {
    final flagDef = config.flags[name];
    if (flagDef != null && flagDef.removeDefinition) {
      return true;
    }

    // Check aliases
    for (final flagDef in config.flags.values) {
      if (flagDef.aliases.contains(name) && flagDef.removeDefinition) {
        return true;
      }
    }

    return false;
  }
}
