## 1.1.1

- **FIX**: Resolve offset mismatch causing RangeError when removing variable declarations
- Cache AST visitor to avoid duplicate traversals
- Re-analyze transformed source before flag definition removal
- Add validation for node offsets

## 1.1.0

- **MAJOR**: Add variable tracking for flags stored in variables (Riverpod pattern support)
- Support nested pattern matching (e.g., `*.watch(releaseFlagProvider`)
- Automatically remove variable declarations that hold flag values
- Handle flag references through variables in control flow
- Add comprehensive examples for Riverpod patterns
- Update documentation with variable tracking capabilities

## 1.0.3

- Add `owner` and `expire` fields to flag definitions for better tracking
- Add expiration warnings for flags past their expire date
- Enhance debug output to display flag metadata (owner, expiration)
- Update example configuration with owner and expire fields
- Update README documentation with new flag metadata options

## 1.0.2

- Improve version parsing in config to handle different types
- Refactor block extraction logic for better code promotion
- Update example configuration patterns

## 1.0.1

- Update installation instructions in README for pub.dev
- Documentation improvements

## 1.0.0

- Initial release of Chado
- Feature flag detection with configurable patterns
- Dead code elimination based on flag values
- Automatic import cleanup
- Flag definition removal
- Support for if/else statements, ternary operators, and complex conditions
- Dry run mode for previewing changes
- Verbose logging option
- File and directory exclusion patterns
- YAML and JSON configuration support
- Code formatting preservation
