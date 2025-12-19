import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'flag_config.dart';

/// Loads and parses configuration files (YAML or JSON) into FlagConfig objects.
class ConfigLoader {
  /// Load configuration from a file path.
  ///
  /// Supports both YAML (.yaml, .yml) and JSON (.json) formats.
  /// The format is determined by the file extension.
  Future<FlagConfig> load(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw ConfigLoaderException('Configuration file not found: $path');
    }

    final content = await file.readAsString();
    final extension = path.toLowerCase().split('.').last;

    try {
      Map<String, dynamic> data;

      if (extension == 'yaml' || extension == 'yml') {
        data = _parseYaml(content);
      } else if (extension == 'json') {
        data = _parseJson(content);
      } else {
        throw ConfigLoaderException(
          'Unsupported file format: $extension. Use .yaml, .yml, or .json',
        );
      }

      return FlagConfig.fromMap(data);
    } catch (e) {
      if (e is ConfigLoaderException) rethrow;
      throw ConfigLoaderException(
        'Failed to parse configuration file: $e',
      );
    }
  }

  Map<String, dynamic> _parseYaml(String content) {
    try {
      final yaml = loadYaml(content);
      return _convertYamlToMap(yaml);
    } catch (e) {
      throw ConfigLoaderException('Invalid YAML format: $e');
    }
  }

  Map<String, dynamic> _parseJson(String content) {
    try {
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        throw ConfigLoaderException('JSON root must be an object');
      }
      return json;
    } catch (e) {
      throw ConfigLoaderException('Invalid JSON format: $e');
    }
  }

  /// Convert YAML dynamic types to proper Map<String, dynamic>.
  Map<String, dynamic> _convertYamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map((key, value) {
        return MapEntry(
          key.toString(),
          _convertYamlValue(value),
        );
      });
    } else if (yaml is Map) {
      return yaml.map((key, value) {
        return MapEntry(
          key.toString(),
          _convertYamlValue(value),
        );
      });
    }
    throw ConfigLoaderException('Expected YAML map at root level');
  }

  dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      return value.map((key, val) {
        return MapEntry(key.toString(), _convertYamlValue(val));
      });
    } else if (value is YamlList) {
      return value.map(_convertYamlValue).toList();
    } else if (value is List) {
      return value.map(_convertYamlValue).toList();
    } else if (value is Map) {
      return value.map((key, val) {
        return MapEntry(key.toString(), _convertYamlValue(val));
      });
    }
    return value;
  }

  /// Validate that the configuration has required fields and valid values.
  ///
  /// Returns a list of warning messages (e.g., for expired flags).
  List<String> validate(FlagConfig config) {
    final warnings = <String>[];

    if (config.flags.isEmpty) {
      throw ConfigLoaderException('Configuration must contain at least one flag');
    }

    for (final entry in config.flags.entries) {
      final flagName = entry.key;
      final flag = entry.value;

      if (flagName.isEmpty) {
        throw ConfigLoaderException('Flag name cannot be empty');
      }

      // Check for duplicate aliases across flags
      for (final alias in flag.aliases) {
        for (final otherEntry in config.flags.entries) {
          if (otherEntry.key == flagName) continue;
          if (otherEntry.value.matches(alias)) {
            throw ConfigLoaderException(
              'Duplicate flag name/alias: $alias is used by both '
              '$flagName and ${otherEntry.key}',
            );
          }
        }
      }

      // Check for expired flags
      if (flag.isExpired && flag.expirationWarning != null) {
        warnings.add(flag.expirationWarning!);
      }
    }

    return warnings;
  }
}

/// Exception thrown when configuration loading fails.
class ConfigLoaderException implements Exception {
  final String message;

  ConfigLoaderException(this.message);

  @override
  String toString() => 'ConfigLoaderException: $message';
}
