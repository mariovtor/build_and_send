library build_and_send;

import 'dart:io';

import 'package:build_and_send/src/constants.dart';

/// Load environment variables from a file
/// This class will load environment variables from a file
/// and store them in a map
class EnvLoader {
  static final Map<String, String> environment = {};

  static void load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      print(
          '$envFile file not found. Please create a $envFile file with the necessary configuration.');
      exit(1);
    }

    final lines = file.readAsLinesSync();
    for (var line in lines) {
      if (line.startsWith('#') || line.isEmpty) {
        continue;
      }
      final parts = line.split('=');
      if (parts.length != 2) {
        continue;
      }
      final key = parts[0].trim();
      final value = parts[1].trim();
      environment[key] = value;
    }
  }

  /// Get the value of an environment variable
  /// This method will return the value of an environment variable
  /// if it exists, otherwise it will return null
  static String? get(String key) {
    return environment[key];
  }
}
