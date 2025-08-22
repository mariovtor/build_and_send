library build_and_send;

import 'input_validator.dart';

/// Validates environment variables from build.env
class EnvValidator {
  /// Validates GCloud related environment variables
  static void validateGCloudEnv(Map<String, String> envVars) {
    final serviceAccount = envVars['GCLOUD_SERVICE_ACCOUNT'];
    if (serviceAccount != null && serviceAccount.isNotEmpty) {
      InputValidator.validateFilePath(serviceAccount, 'GCLOUD_SERVICE_ACCOUNT');
    }

    final projectId = envVars['GCLOUD_PROJECT_ID'];
    if (projectId != null && projectId.isNotEmpty) {
      if (projectId.contains(' ')) {
        throw ValidationException('GCLOUD_PROJECT_ID cannot contain spaces');
      }
    }
  }

  /// Validates iOS TestFlight related environment variables
  static void validateIOSEnv(Map<String, String> envVars) {
    final uploadEmail = envVars['IOS_UPLOAD_EMAIL'] ?? envVars['ACCOUNT_EMAIL'];
    if (uploadEmail != null && uploadEmail.isNotEmpty) {
      InputValidator.validateEmail(uploadEmail, 'iOS upload email');
    }

    // Validate that password is not empty if email is provided
    final uploadPassword =
        envVars['IOS_UPLOAD_PASSWORD'] ?? envVars['ACCOUNT_PASSWORD'];
    if (uploadEmail != null &&
        uploadEmail.isNotEmpty &&
        (uploadPassword == null || uploadPassword.isEmpty)) {
      throw ValidationException(
          'IOS_UPLOAD_PASSWORD is required when IOS_UPLOAD_EMAIL is provided');
    }
  }

  /// Validates Discord webhook environment variables
  static void validateDiscordEnv(Map<String, String> envVars) {
    final webhookUrl = envVars['DISCORD_WEBHOOK_URL'];
    if (webhookUrl != null && webhookUrl.isNotEmpty) {
      InputValidator.validateUrl(webhookUrl, 'DISCORD_WEBHOOK_URL');
    }
  }

  /// Validates all environment variables
  static void validateAll(Map<String, String> envVars) {
    validateGCloudEnv(envVars);
    validateIOSEnv(envVars);
    validateDiscordEnv(envVars);
  }

  /// Sanitizes environment variables
  static Map<String, String> sanitizeEnvVars(Map<String, String> envVars) {
    final sanitized = <String, String>{};

    for (final entry in envVars.entries) {
      final key = InputValidator.sanitizeString(entry.key);
      final value = InputValidator.sanitizeString(entry.value);
      sanitized[key] = value;
    }

    return sanitized;
  }
}
