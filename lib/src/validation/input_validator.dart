library build_and_send;

import 'dart:io';

/// Exception thrown when command-line argument validation fails
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Validates command-line arguments and configuration values
class InputValidator {
  /// Validates platform argument
  static void validatePlatform(String? platform) {
    if (platform == null) return;

    const validPlatforms = ['android', 'ios', 'all'];
    if (!validPlatforms.contains(platform)) {
      throw ValidationException(
        'Invalid platform "$platform". Must be one of: ${validPlatforms.join(', ')}',
      );
    }
  }

  /// Validates flavor name format
  static void validateFlavorName(String? flavorName) {
    if (flavorName == null || flavorName.isEmpty) return;

    // Check for valid identifier format (letters, numbers, underscore)
    final validFormat = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    if (!validFormat.hasMatch(flavorName)) {
      throw ValidationException(
        'Invalid flavor name "$flavorName". Must be a valid identifier (letters, numbers, underscore only)',
      );
    }
  }

  /// Validates mention names format
  static void validateMentionNames(List<String>? mentionNames) {
    if (mentionNames == null) return;

    for (final name in mentionNames) {
      if (name.trim().isEmpty) {
        throw ValidationException('Mention names cannot be empty');
      }

      // Check for potentially dangerous characters
      if (name.contains(RegExp(r'[<>"' "'" r']'))) {
        throw ValidationException(
          'Invalid mention name "$name". Contains unsafe characters',
        );
      }
    }
  }

  /// Validates custom text input
  static void validateCustomText(String? customText) {
    if (customText == null || customText.isEmpty) return;

    // Limit length to prevent abuse
    if (customText.length > 1000) {
      throw ValidationException(
        'Custom text too long. Maximum 1000 characters allowed',
      );
    }

    // Check for potential injection attempts
    const dangerousPatterns = [
      r'\$\(', // Command substitution
      r'`', // Backticks
      r'\|\s*\w', // Pipe to commands
      r';\s*\w', // Command chaining
      r'&&\s*\w', // Command chaining
      r'\|\|\s*\w', // Command chaining
    ];

    for (final pattern in dangerousPatterns) {
      if (RegExp(pattern).hasMatch(customText)) {
        throw ValidationException(
          'Custom text contains potentially unsafe content',
        );
      }
    }
  }

  /// Validates file paths to prevent directory traversal
  static void validateFilePath(String? filePath, String fieldName) {
    if (filePath == null || filePath.isEmpty) return;

    // Check for directory traversal attempts
    if (filePath.contains('..')) {
      throw ValidationException(
        '$fieldName contains directory traversal sequence ".."',
      );
    }

    // Check for absolute path outside project (basic check)
    if (filePath.startsWith('/') &&
        !filePath.startsWith(Directory.current.path)) {
      throw ValidationException(
        '$fieldName should be relative to project directory',
      );
    }
  }

  /// Validates email format
  static void validateEmail(String? email, String fieldName) {
    if (email == null || email.isEmpty) return;

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      throw ValidationException(
        '$fieldName must be a valid email address',
      );
    }
  }

  /// Validates URL format
  static void validateUrl(String? url, String fieldName) {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw ValidationException(
          '$fieldName must be a valid HTTP/HTTPS URL',
        );
      }
    } catch (e) {
      throw ValidationException(
        '$fieldName must be a valid URL',
      );
    }
  }

  /// Sanitizes string input by removing potentially dangerous characters
  static String sanitizeString(String input) {
    return input
        .replaceAll(RegExp(r'[<>"' "'" r'\$`]'), '') // Remove dangerous chars
        .trim();
  }

  /// Sanitizes command arguments
  static String sanitizeCommandArg(String arg) {
    // Allow only safe characters in command arguments
    return arg.replaceAll(RegExp(r'[;&|`$(){}[\]<>]'), '').trim();
  }
}
