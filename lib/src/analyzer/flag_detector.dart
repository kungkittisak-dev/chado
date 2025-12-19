import 'package:analyzer/dart/ast/ast.dart';
import '../config/flag_config.dart';
import '../models/flag_reference.dart';
import '../visitor/flag_usage_visitor.dart';

/// Detects feature flag usages in AST.
class FlagDetector {
  final FlagConfig config;

  FlagDetector(this.config);

  /// Detect all feature flag references in a compilation unit.
  List<FlagReference> detectFlags(CompilationUnit unit) {
    final visitor = FlagUsageVisitor(config);
    unit.visitChildren(visitor);
    return visitor.flagReferences;
  }

  /// Detect flag definitions in a compilation unit.
  ///
  /// This finds places where flags are defined (const declarations, fields, etc.)
  /// that should be removed if configured to do so.
  List<FlagDefinitionLocation> detectFlagDefinitions(CompilationUnit unit) {
    final definitions = <FlagDefinitionLocation>[];

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
