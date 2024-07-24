// ignore_for_file: public_member_api_docs, sort_constructors_first
library build_and_send;

import 'dart:io';

import 'package:yaml/yaml.dart';

class BuildConfig {
  final String method;
  final AndroidConfig android;
  final IosConfig ios;
  final Map<String, FlavorConfig> flavors;
  final DiscordConfig? discord;

  BuildConfig({
    required this.method,
    required this.android,
    required this.ios,
    required this.flavors,
    required this.discord,
  });

  factory BuildConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    var flavors = <String, FlavorConfig>{};
    if (yaml['build']?['flavors'] is Map) {
      (yaml['build']?['flavors'] as Map).forEach((key, value) {
        if (value == null) return;
        flavors[key] = FlavorConfig.fromYaml(value);
      });
    }

    return BuildConfig(
      method: yaml['method'] ?? 'default',
      android: AndroidConfig.fromYaml(yaml['android'] ?? {}),
      ios: IosConfig.fromYaml(yaml['ios'] ?? {}),
      flavors: flavors,
      discord: DiscordConfig.fromYaml(yaml['discord'] ?? {}),
    );
  }

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
  final String? buildArgs;
  final String apkPath;
  final String bundlePath;
  final GCloudConfig? gcloud;
  final String apkName;
  final String bundleName;

  AndroidConfig({
    this.buildArgs,
    required this.apkPath,
    required this.bundlePath,
    this.gcloud,
    required this.apkName,
    required this.bundleName,
  });

  factory AndroidConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return AndroidConfig(
      buildArgs: yaml['build_args'],
      apkPath: yaml['apk_path'] ?? 'build/app/outputs/flutter-apk/',
      bundlePath: yaml['bundle_path'] ?? 'build/outputs/bundle/',
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

class IosConfig {
  final String? buildArgs;
  final String? ipaName;

  IosConfig({
    this.buildArgs,
    this.ipaName,
  });

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

class FlavorConfig {
  final String method;
  final AndroidConfig android;
  final IosConfig ios;

  FlavorConfig({
    required this.method,
    required this.android,
    required this.ios,
  });

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

class GCloudConfig {
  final String bucket;
  final String appId;

  GCloudConfig({
    required this.bucket,
    required this.appId,
  });

  factory GCloudConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return GCloudConfig(
      bucket: yaml['bucket'],
      appId: yaml['app_id'],
    );
  }

  @override
  String toString() => 'GCloudConfig(bucket: $bucket, appId: $appId)';
}

class DiscordConfig {
  final String webhookUrl;
  final String? channelId;
  final Map<String, String>? mentionUsers;
  final bool showVersion;
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
