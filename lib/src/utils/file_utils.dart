import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility functions for file operations.
class FileUtils {
  /// Find all Dart files in the given directory recursively.
  ///
  /// [targetPath] can be a file or directory.
  /// [excludePatterns] are glob-like patterns to exclude (e.g., '**/generated/**').
  static Future<List<File>> findDartFiles(
    String targetPath, {
    List<String> excludePatterns = const [],
  }) async {
    final target = File(targetPath);

    // If targetPath is a file, return it if it's a Dart file
    if (await target.exists()) {
      if (targetPath.endsWith('.dart')) {
        return [target];
      }
      throw FileUtilsException('Target is not a Dart file: $targetPath');
    }

    // Otherwise, treat as directory
    final directory = Directory(targetPath);
    if (!await directory.exists()) {
      throw FileUtilsException('Target not found: $targetPath');
    }

    final dartFiles = <File>[];

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Check exclude patterns
        if (!_shouldExclude(entity.path, excludePatterns)) {
          dartFiles.add(entity);
        }
      }
    }

    return dartFiles;
  }

  /// Check if a file path should be excluded based on patterns.
  static bool _shouldExclude(String filePath, List<String> patterns) {
    for (final pattern in patterns) {
      if (_matchesPattern(filePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Simple glob-like pattern matching.
  static bool _matchesPattern(String filePath, String pattern) {
    final normalized = path.normalize(filePath);

    // Handle ** (match any directory depth)
    if (pattern.contains('**')) {
      final regex = RegExp(
        pattern
            .replaceAll('**', '.*')
            .replaceAll('*', '[^/]*')
            .replaceAll('.', r'\.'),
      );
      return regex.hasMatch(normalized);
    }

    // Handle * (match within single directory)
    if (pattern.contains('*')) {
      final regex = RegExp(
        pattern.replaceAll('*', '[^/]*').replaceAll('.', r'\.'),
      );
      return regex.hasMatch(normalized);
    }

    // Exact match
    return normalized.contains(pattern);
  }

  /// Read a file and return its contents as a string.
  static Future<String> readFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw FileUtilsException('Failed to read file ${file.path}: $e');
    }
  }

  /// Write content to a file.
  static Future<void> writeFile(File file, String content) async {
    try {
      await file.writeAsString(content);
    } catch (e) {
      throw FileUtilsException('Failed to write file ${file.path}: $e');
    }
  }

  /// Get the relative path from a base directory to a file.
  static String getRelativePath(String basePath, String filePath) {
    return path.relative(filePath, from: basePath);
  }

  /// Ensure a directory exists, creating it if necessary.
  static Future<void> ensureDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}

/// Exception thrown by file utility operations.
class FileUtilsException implements Exception {
  final String message;

  FileUtilsException(this.message);

  @override
  String toString() => 'FileUtilsException: $message';
}
