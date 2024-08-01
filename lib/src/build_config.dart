// ignore_for_file: public_member_api_docs, sort_constructors_first
library build_and_send;

import 'dart:io';

import 'package:yaml/yaml.dart';

/// Build config class
/// This class will hold the build configuration
/// for the project
class BuildConfig {
  /// [method] Build method
  /// This will be used to determine the build method
  /// Default is 'default', values can be `fvm`, `shorebird`. See README for more details
  final String method;

  /// [android] Android configuration
  final AndroidConfig android;

  /// [ios] iOS configuration
  final IosConfig ios;

  /// [flavors] Flavors configuration
  /// This will hold the configuration for different flavors
  /// of the project
  /// Come from `build_config.yaml` file flavors section
  final Map<String, FlavorConfig> flavors;

  /// [discord] Discord configuration
  /// This will hold the configuration for discord
  /// Come from `build_config.yaml` file discord section
  final DiscordConfig? discord;

  BuildConfig({
    required this.method,
    required this.android,
    required this.ios,
    required this.flavors,
    required this.discord,
  });

  /// Create a new instance of BuildConfig from yaml
  factory BuildConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    var flavors = <String, FlavorConfig>{};
    if (yaml['build']?['flavors'] is Map) {
      (yaml['build']?['flavors'] as Map).forEach((key, value) {
        if (value == null) return;
        flavors[key] = FlavorConfig.fromYaml(value);
      });
    }

    return BuildConfig(
      method: yaml['build']?['method'] ?? 'default',
      android: AndroidConfig.fromYaml(yaml['build']?['android'] ?? {}),
      ios: IosConfig.fromYaml(yaml['build']?['ios'] ?? {}),
      flavors: flavors,
      discord: DiscordConfig.fromYaml(yaml['discord'] ?? {}),
    );
  }

  /// Load build config from a file
  static BuildConfig load(String path) {
    final file = File(path);
    final yaml = loadYaml(file.readAsStringSync()) as Map;
    return BuildConfig.fromYaml(yaml);
  }

  @override
  String toString() {
    return 'BuildConfig(method: $method, android: $android, ios: $ios, flavors: $flavors, discord: $discord)';
  }
}

class AndroidConfig {
  /// [buildArgs] Build arguments
  final String? buildArgs;

  /// [apkPath] APK path
  final String apkPath;

  /// [bundlePath] Bundle path
  final String bundlePath;

  /// [gcloud] GCloud configuration
  final GCloudConfig? gcloud;

  /// [apkName] APK name
  final String apkName;

  /// [bundleName] Bundle name
  final String bundleName;

  AndroidConfig({
    this.buildArgs,
    required this.apkPath,
    required this.bundlePath,
    this.gcloud,
    required this.apkName,
    required this.bundleName,
  });

  /// Create a new instance of AndroidConfig from yaml
  factory AndroidConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return AndroidConfig(
      buildArgs: yaml['build_args'],
      apkPath: yaml['apk_path'] ?? 'build/app/outputs/flutter-apk/',
      bundlePath: yaml['bundle_path'] ?? 'build/app/outputs/bundle/release',
      apkName: yaml['apk_name'] ?? 'app-release.apk',
      bundleName: yaml['bundle_name'] ?? 'app-release.aab',
      gcloud:
          yaml['gcloud'] != null ? GCloudConfig.fromYaml(yaml['gcloud']) : null,
    );
  }

  @override
  String toString() {
    return 'AndroidConfig(buildArgs: $buildArgs, apkPath: $apkPath, bundlePath: $bundlePath, gcloud: $gcloud)';
  }
}

///
/// iOS configuration
/// This class will hold the configuration for iOS
class IosConfig {
  /// [buildArgs] Build arguments
  final String? buildArgs;

  /// [ipaName] IPA name
  final String? ipaName;

  IosConfig({
    this.buildArgs,
    this.ipaName,
  });

  /// Create a new instance of IosConfig from yaml
  factory IosConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return IosConfig(
      buildArgs: yaml['build_args'],
      ipaName: yaml['ipa_name'],
    );
  }

  @override
  String toString() {
    return 'IosConfig(buildArgs: $buildArgs, ipaName: $ipaName)';
  }
}

///
/// Flavor configuration
class FlavorConfig {
  /// [method] Build method
  final String method;

  /// [android] Android configuration
  final AndroidConfig android;

  /// [ios] iOS configuration
  final IosConfig ios;

  FlavorConfig({
    required this.method,
    required this.android,
    required this.ios,
  });

  /// Create a new instance of FlavorConfig from yaml
  factory FlavorConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return FlavorConfig(
      method: yaml['method'] ?? 'default',
      android: AndroidConfig.fromYaml(yaml['android'] ?? {}),
      ios: IosConfig.fromYaml(yaml['ios'] ?? {}),
    );
  }

  @override
  String toString() =>
      'FlavorConfig(method: $method, android: $android, ios: $ios)';
}

///
/// GCloud configuration
class GCloudConfig {
  /// [bucket] Bucket name in GCloud storage, where to upload the files
  final String bucket;

  /// [appId] App ID in GCloud storage
  final String appId;

  GCloudConfig({
    required this.bucket,
    required this.appId,
  });

  /// Create a new instance of GCloudConfig from yaml
  factory GCloudConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return GCloudConfig(
      bucket: yaml['bucket'],
      appId: yaml['app_id'],
    );
  }

  @override
  String toString() => 'GCloudConfig(bucket: $bucket, appId: $appId)';
}

/// Discord configuration
class DiscordConfig {
  /// [webhookUrl] Webhook URL to send the notification
  final String webhookUrl;

  /// [channelId] Channel ID to tag in the notification
  final String? channelId;

  /// [mentionUsers] Mention users in the notification
  final Map<String, String>? mentionUsers;

  /// [showVersion] Show version in the notification, default is true, then will show version in pubspect.yaml
  final bool showVersion;

  /// [showFlavor] Show flavor in the notification, default is true, then will show flavor in build_config.yaml
  final bool showFlavor;

  DiscordConfig({
    required this.webhookUrl,
    this.channelId,
    this.mentionUsers,
    this.showVersion = true,
    this.showFlavor = true,
  });

  static DiscordConfig? fromYaml(Map<dynamic, dynamic> yaml) {
    if (yaml.isEmpty) return null;
    var mentionUsers = <String, String>{};
    if (yaml['mention_users'] != null) {
      (yaml['mention_users'] as String).split(',').forEach((user) {
        var parts = user.split(':');
        mentionUsers[parts[0]] = parts[1];
      });
    }

    return DiscordConfig(
      webhookUrl: yaml['webhook_url'],
      channelId: yaml['channel_id']?.toString(),
      mentionUsers: mentionUsers.isNotEmpty ? mentionUsers : null,
      showVersion: yaml['show_version'] ?? true,
      showFlavor: yaml['show_flavor'] ?? true,
    );
  }
}
