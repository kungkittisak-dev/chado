# Chado

A Dart CLI tool for automatically removing feature flags from Dart code, inspired by Uber's Piranha.

## Features

- 🎯 **Pattern Matching**: Detects feature flag service calls with configurable patterns
- 🧹 **Dead Code Elimination**: Removes unreachable code branches based on flag values
- 📦 **Import Cleanup**: Automatically removes unused imports
- 🔧 **Flag Definition Removal**: Removes flag constant definitions
- 💅 **Code Formatting**: Preserves or applies Dart formatting
- 🔍 **Dry Run Mode**: Preview changes before applying them

## Installation

```bash
# Install globally
dart pub global activate chado

# Or add to pubspec.yaml
dependencies:
  chado: ^1.0.0
```

## Usage

### Basic Usage

```bash
# Process a directory
chado --config=flags.yaml --target=lib/

# Process a single file
chado --config=flags.yaml --target=lib/my_file.dart

# Dry run (preview changes)
chado --config=flags.yaml --target=lib/ --dry-run

# Verbose output
chado --config=flags.yaml --target=lib/ --verbose

# Exclude patterns
chado --config=flags.yaml --target=lib/ --exclude="**/*.g.dart,**/*.freezed.dart"
```

### CLI Options

- `-c, --config`: Path to configuration file (YAML or JSON) [required]
- `-t, --target`: Target file or directory to process [required]
- `-d, --dry-run`: Preview changes without modifying files
- `-v, --verbose`: Show verbose output
- `-e, --exclude`: Comma-separated list of patterns to exclude
- `-h, --help`: Show help message

## Configuration

Create a `flags.yaml` configuration file:

```yaml
version: 1.0

# Define patterns to detect feature flags
patterns:
  methods:
    - "FeatureFlagService.isEnabled"
    - "FeatureFlags.check"
    - "*.isFeatureEnabled"
  classes:
    - "FeatureFlagService"

# Flag definitions with resolved values
flags:
  new_feature:
    value: true
    remove_definition: true
    description: "Feature rolled out to 100%"
    owner: "frontend-team"
    ticket: "FEAT-456"
    expire: "2025-12-31"

  experimental_feature:
    value: false
    remove_definition: true
    owner: "backend-team"
    expire: "2025-06-30"
    aliases:
      - "exp_feature"

settings:
  preserve_comments: true
  format_output: true
```

### Configuration Options

#### Patterns
- `methods`: List of method call patterns to detect (supports wildcards)
- `classes`: List of class names that provide flag services

#### Flags
Each flag definition includes:
- `value`: The resolved boolean value (true/false) **[required]**
- `remove_definition`: Whether to remove the flag definition (default: true)
- `aliases`: Alternative names for the flag (optional)
- `description`: Human-readable description (optional)
- `ticket`: Related ticket/issue number (optional)
- `owner`: Owner or team responsible for the flag (optional)
- `expire`: Expiration date in ISO format (YYYY-MM-DD) - triggers warnings if expired (optional)

#### Settings
- `preserve_comments`: Keep comments in transformed code (default: true)
- `remove_empty_blocks`: Remove empty code blocks (default: true)
- `format_output`: Apply dart_style formatting (default: true)

## How It Works

Chado transforms your code through these steps:

### 1. Detection
Finds feature flag method calls matching configured patterns:

```dart
if (FeatureFlagService.isEnabled('new_feature')) {
  // ...
}
```

### 2. Analysis
Analyzes control flow to determine which code branches are dead:

```dart
// If new_feature = true
if (flag) {
  doNewThing();  // ← Keep this (live code)
} else {
  doOldThing();  // ← Remove this (dead code)
}
```

### 3. Transformation
Removes dead code and promotes live code:

```dart
// Result
doNewThing();
```

### 4. Cleanup
Removes unused imports and flag definitions.

## Examples

### Before Transformation

```dart
import 'package:app/feature_flags.dart';

class MyService {
  void process() {
    if (FeatureFlagService.isEnabled('new_feature')) {
      useNewImplementation();
    } else {
      useOldImplementation();
    }

    final mode = FeatureFlagService.isEnabled('experimental')
        ? experimentalMode()
        : stableMode();
  }
}
```

### Configuration

```yaml
flags:
  new_feature:
    value: true
    remove_definition: true
  experimental:
    value: false
    remove_definition: true
```

### After Transformation

```dart
class MyService {
  void process() {
    useNewImplementation();

    final mode = stableMode();
  }
}
```

## Supported Patterns

### Simple If/Else

```dart
if (flags.isEnabled('feature')) {
  // Kept if feature=true
} else {
  // Kept if feature=false
}
```

### Ternary Operators

```dart
final value = flags.isEnabled('feature') ? newValue : oldValue;
// Becomes: final value = newValue; (if feature=true)
```

### Complex Conditions

```dart
if (flags.isEnabled('feature') && otherCondition()) {
  // Simplified to: if (otherCondition()) { ... }
}
```

### Negation

```dart
if (!flags.isEnabled('feature')) {
  // Handles negated flags correctly
}
```

## Limitations

- Only supports pure Dart code (no Flutter-specific widgets)
- Handles simple to moderately complex boolean expressions
- Does not trace const values across files
- Cannot simplify highly complex nested conditions

## Development

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/unit/config/config_loader_test.dart

# Run with coverage
dart test --coverage=coverage
```

### Project Structure

```
chado/
├── bin/
│   └── chado.dart              # CLI entry point
├── lib/
│   ├── chado.dart              # Public API
│   └── src/
│       ├── cli/                # CLI handling
│       ├── config/             # Configuration models
│       ├── analyzer/           # AST analysis
│       ├── visitor/            # AST visitors
│       ├── transformer/        # Code transformation
│       ├── rewriter/           # AST rewriting
│       ├── models/             # Data models
│       └── utils/              # Utilities
├── test/
│   ├── fixtures/               # Test files
│   ├── unit/                   # Unit tests
│   └── integration/            # Integration tests
└── example/                    # Examples
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

Inspired by [Uber's Piranha](https://github.com/uber/piranha) tool for automated feature flag cleanup.
