library build_and_send;

import '../build_config.dart';
import 'input_validator.dart';

/// Validates build configuration values
class ConfigValidator {
  /// Validates the entire BuildConfig object
  static void validateBuildConfig(BuildConfig config) {
    _validateMethod(config.method);
    _validateAndroidConfig(config.android);
    _validateIOSConfig(config.ios);
    _validateFlavors(config.flavors);
    _validateDiscordConfig(config.discord);
  }

  static void _validateMethod(String method) {
    const validMethods = ['default', 'fvm', 'shorebird'];
    if (!validMethods.contains(method)) {
      throw ValidationException(
        'Invalid build method "$method". Must be one of: ${validMethods.join(', ')}',
      );
    }
  }

  static void _validateAndroidConfig(AndroidConfig android) {
    // Validate paths exist as directories
    _validateDirectoryPath(android.apkPath, 'Android APK path');
    _validateDirectoryPath(android.bundlePath, 'Android bundle path');

    // Validate GCloud config if present
    if (android.gcloud != null) {
      _validateGCloudConfig(android.gcloud!);
    }

    // Validate file names
    if (android.apkName.isEmpty) {
      throw ValidationException('Android APK name cannot be empty');
    }
    if (android.bundleName.isEmpty) {
      throw ValidationException('Android bundle name cannot be empty');
    }
  }

  static void _validateIOSConfig(IosConfig ios) {
    // iOS config is mostly optional, just validate format if present
    if (ios.ipaName != null && ios.ipaName!.isEmpty) {
      throw ValidationException('iOS IPA name cannot be empty when specified');
    }
  }

  static void _validateFlavors(Map<String, FlavorConfig> flavors) {
    for (final entry in flavors.entries) {
      final flavorName = entry.key;
      final flavorConfig = entry.value;

      InputValidator.validateFlavorName(flavorName);
      _validateFlavorConfig(flavorConfig, flavorName);
    }
  }

  static void _validateFlavorConfig(FlavorConfig flavor, String flavorName) {
    _validateMethod(flavor.method);
    _validateAndroidConfig(flavor.android);
    _validateIOSConfig(flavor.ios);
  }

  static void _validateGCloudConfig(GCloudConfig gcloud) {
    if (gcloud.bucket.isEmpty) {
      throw ValidationException('GCloud bucket name cannot be empty');
    }

    if (gcloud.appId.isEmpty) {
      throw ValidationException('GCloud app_id cannot be empty');
    }

    // Validate bucket name format (basic GCS rules)
    final bucketRegex = RegExp(r'^[a-z0-9][a-z0-9_.-]*[a-z0-9]$');
    if (!bucketRegex.hasMatch(gcloud.bucket)) {
      throw ValidationException(
        'Invalid GCloud bucket name format. Must follow GCS naming rules',
      );
    }

    // Validate app_id format (basic check)
    if (gcloud.appId.contains(' ')) {
      throw ValidationException('GCloud app_id cannot contain spaces');
    }
  }

  static void _validateDiscordConfig(DiscordConfig? discord) {
    if (discord == null) return;

    if (discord.webhookUrl.isEmpty) {
      throw ValidationException('Discord webhook URL cannot be empty');
    }

    InputValidator.validateUrl(discord.webhookUrl, 'Discord webhook URL');

    // Validate mention users format if present
    if (discord.mentionUsers != null) {
      for (final entry in discord.mentionUsers!.entries) {
        if (entry.key.trim().isEmpty || entry.value.trim().isEmpty) {
          throw ValidationException('Discord mention user names cannot be empty');
        }
      }
    }
  }

  static void _validateDirectoryPath(String path, String description) {
    if (path.isEmpty) {
      throw ValidationException('$description cannot be empty');
    }

    InputValidator.validateFilePath(path, description);
  }

  /// Sanitizes configuration values
  static BuildConfig sanitizeConfig(BuildConfig config) {
    return BuildConfig(
      method: InputValidator.sanitizeString(config.method),
      android: _sanitizeAndroidConfig(config.android),
      ios: _sanitizeIOSConfig(config.ios),
      discord: config.discord != null ? _sanitizeDiscordConfig(config.discord!) : null,
      flavors: _sanitizeFlavors(config.flavors),
    );
  }

  static AndroidConfig _sanitizeAndroidConfig(AndroidConfig android) {
    return AndroidConfig(
      buildArgs: android.buildArgs != null 
          ? InputValidator.sanitizeString(android.buildArgs!) 
          : null,
      apkPath: InputValidator.sanitizeString(android.apkPath),
      bundlePath: InputValidator.sanitizeString(android.bundlePath),
      apkName: InputValidator.sanitizeString(android.apkName),
      bundleName: InputValidator.sanitizeString(android.bundleName),
      gcloud: android.gcloud != null ? _sanitizeGCloudConfig(android.gcloud!) : null,
    );
  }

  static IosConfig _sanitizeIOSConfig(IosConfig ios) {
    return IosConfig(
      buildArgs: ios.buildArgs != null 
          ? InputValidator.sanitizeString(ios.buildArgs!) 
          : null,
      ipaName: ios.ipaName != null
          ? InputValidator.sanitizeString(ios.ipaName!)
          : null,
    );
  }

  static GCloudConfig _sanitizeGCloudConfig(GCloudConfig gcloud) {
    return GCloudConfig(
      bucket: InputValidator.sanitizeString(gcloud.bucket),
      appId: InputValidator.sanitizeString(gcloud.appId),
    );
  }

  static DiscordConfig _sanitizeDiscordConfig(DiscordConfig discord) {
    Map<String, String>? sanitizedMentionUsers;
    if (discord.mentionUsers != null) {
      sanitizedMentionUsers = {};
      for (final entry in discord.mentionUsers!.entries) {
        final sanitizedKey = InputValidator.sanitizeString(entry.key);
        final sanitizedValue = InputValidator.sanitizeString(entry.value);
        sanitizedMentionUsers[sanitizedKey] = sanitizedValue;
      }
    }

    return DiscordConfig(
      webhookUrl: InputValidator.sanitizeString(discord.webhookUrl),
      channelId: discord.channelId != null
          ? InputValidator.sanitizeString(discord.channelId!)
          : null,
      mentionUsers: sanitizedMentionUsers,
      showVersion: discord.showVersion,
      showFlavor: discord.showFlavor,
    );
  }

  static Map<String, FlavorConfig> _sanitizeFlavors(Map<String, FlavorConfig> flavors) {
    final sanitized = <String, FlavorConfig>{};
    
    for (final entry in flavors.entries) {
      final sanitizedKey = InputValidator.sanitizeString(entry.key);
      sanitized[sanitizedKey] = _sanitizeFlavorConfig(entry.value);
    }
    
    return sanitized;
  }

  static FlavorConfig _sanitizeFlavorConfig(FlavorConfig flavor) {
    return FlavorConfig(
      method: InputValidator.sanitizeString(flavor.method),
      android: _sanitizeAndroidConfig(flavor.android),
      ios: _sanitizeIOSConfig(flavor.ios),
    );
  }
}
