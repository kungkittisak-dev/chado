import 'package:logging/logging.dart';

/// Logger utility for Chado CLI tool.
class ChadoLogger {
  static final _logger = Logger('chado');
  static bool _initialized = false;

  /// Initialize the logger with the specified verbosity level.
  static void initialize({bool verbose = false}) {
    if (_initialized) return;

    Logger.root.level = verbose ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      final level = _formatLevel(record.level);
      final message = record.message;
      print('$level$message');
    });

    _initialized = true;
  }

  static String _formatLevel(Level level) {
    if (level == Level.SEVERE) return '[ERROR] ';
    if (level == Level.WARNING) return '[WARN] ';
    if (level == Level.INFO) return '';
    if (level == Level.FINE || level == Level.FINER || level == Level.FINEST) {
      return '[DEBUG] ';
    }
    return '';
  }

  /// Log an info message.
  static void info(String message) {
    _logger.info(message);
  }

  /// Log a debug message (only shown in verbose mode).
  static void debug(String message) {
    _logger.fine(message);
  }

  /// Log a warning message.
  static void warning(String message) {
    _logger.warning(message);
  }

  /// Log an error message.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  /// Log success message (in green if terminal supports it).
  static void success(String message) {
    _logger.info('\u001b[32m✓\u001b[0m $message');
  }

  /// Log a progress indicator.
  static void progress(String message) {
    _logger.info('→ $message');
  }

  /// Log file processing.
  static void file(String filePath, String action) {
    _logger.fine('$action: $filePath');
  }
}
