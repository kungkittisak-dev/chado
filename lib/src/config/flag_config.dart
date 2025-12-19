/// Configuration model for feature flags and patterns.
class FlagConfig {
  final String version;
  final PatternConfig? patterns;
  final Map<String, FlagDefinition> flags;
  final SettingsConfig? settings;

  FlagConfig({
    required this.version,
    this.patterns,
    required this.flags,
    this.settings,
  });

  factory FlagConfig.fromMap(Map<String, dynamic> map) {
    return FlagConfig(
      version: map['version']?.toString() ?? '1.0',
      patterns: map['patterns'] != null
          ? PatternConfig.fromMap(map['patterns'] as Map<String, dynamic>)
          : null,
      flags: (map['flags'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          FlagDefinition.fromMap(key, value as Map<String, dynamic>),
        ),
      ),
      settings: map['settings'] != null
          ? SettingsConfig.fromMap(map['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      if (patterns != null) 'patterns': patterns!.toMap(),
      'flags': flags.map((key, value) => MapEntry(key, value.toMap())),
      if (settings != null) 'settings': settings!.toMap(),
    };
  }
}

/// Pattern configuration for detecting feature flags.
class PatternConfig {
  final List<String> methods;
  final List<String> classes;

  PatternConfig({
    required this.methods,
    required this.classes,
  });

  factory PatternConfig.fromMap(Map<String, dynamic> map) {
    return PatternConfig(
      methods: (map['methods'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      classes: (map['classes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'methods': methods,
      'classes': classes,
    };
  }
}

/// Definition of a single feature flag.
class FlagDefinition {
  final String name;
  final bool value;
  final bool removeDefinition;
  final List<String> aliases;
  final String? description;
  final String? ticket;
  final String? owner;
  final DateTime? expire;

  FlagDefinition({
    required this.name,
    required this.value,
    this.removeDefinition = true,
    this.aliases = const [],
    this.description,
    this.ticket,
    this.owner,
    this.expire,
  });

  factory FlagDefinition.fromMap(String name, Map<String, dynamic> map) {
    DateTime? expireDate;
    if (map['expire'] != null) {
      try {
        expireDate = DateTime.parse(map['expire'].toString());
      } catch (e) {
        // Invalid date format, ignore
      }
    }

    return FlagDefinition(
      name: name,
      value: map['value'] as bool,
      removeDefinition: map['remove_definition'] as bool? ?? true,
      aliases: (map['aliases'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      description: map['description'] as String?,
      ticket: map['ticket'] as String?,
      owner: map['owner'] as String?,
      expire: expireDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'remove_definition': removeDefinition,
      if (aliases.isNotEmpty) 'aliases': aliases,
      if (description != null) 'description': description,
      if (ticket != null) 'ticket': ticket,
      if (owner != null) 'owner': owner,
      if (expire != null) 'expire': expire!.toIso8601String(),
    };
  }

  /// Check if the given flag name matches this definition or any of its aliases.
  bool matches(String flagName) {
    return name == flagName || aliases.contains(flagName);
  }

  /// Check if the flag has expired.
  bool get isExpired {
    if (expire == null) return false;
    return DateTime.now().isAfter(expire!);
  }

  /// Get a warning message if the flag is expired.
  String? get expirationWarning {
    if (!isExpired) return null;

    final daysExpired = DateTime.now().difference(expire!).inDays;
    return 'Flag "$name" expired $daysExpired day(s) ago (${expire!.toIso8601String().split('T')[0]})';
  }
}

/// Global settings for the transformation.
class SettingsConfig {
  final bool preserveComments;
  final bool removeEmptyBlocks;
  final bool formatOutput;

  SettingsConfig({
    this.preserveComments = true,
    this.removeEmptyBlocks = true,
    this.formatOutput = true,
  });

  factory SettingsConfig.fromMap(Map<String, dynamic> map) {
    return SettingsConfig(
      preserveComments: map['preserve_comments'] as bool? ?? true,
      removeEmptyBlocks: map['remove_empty_blocks'] as bool? ?? true,
      formatOutput: map['format_output'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preserve_comments': preserveComments,
      'remove_empty_blocks': removeEmptyBlocks,
      'format_output': formatOutput,
    };
  }
}
