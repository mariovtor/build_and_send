import 'dart:io';

import 'package:build_and_send/src/builders/android_builder.dart';
import 'package:build_and_send/src/builders/builder.dart';
import 'package:test/test.dart';

void main() {
  group('AndroidBuilder', () {
    late AndroidBuilder androidBuilder;
    var runCommandCalls = <String>[];

    Future<void> mockRunCommand(
      String command, {
      String? startMessage,
      String? errorMessage,
      String? successMessage,
      String? progressMessage,
      Function(ProcessResult)? onRun,
    }) async {
      runCommandCalls.add(command);
      // Simulate successful command execution
      if (onRun != null) {
        final mockResult = ProcessResult(1, 0, 'success', '');
        onRun(mockResult);
      }
    }

    setUp(() {
      runCommandCalls.clear();
      androidBuilder = AndroidBuilder(
        buildMethod: 'default',
        verbose: false,
        runCommand: mockRunCommand,
      );
    });

    group('build', () {
      test('should build APK and Bundle when not onlyUpload', () async {
        final context = BuildContext(
          flavorName: 'dev',
          platform: 'android',
          buildArgs: '-t lib/main_dev.dart',
          onlyUpload: false,
        );

        final result = await androidBuilder.build(context);

        expect(result.success, true);
        expect(runCommandCalls, hasLength(2)); // APK + Bundle
        expect(runCommandCalls.first, contains('flutter build apk'));
        expect(runCommandCalls.first, contains('--flavor dev'));
        expect(runCommandCalls.last, contains('flutter build appbundle'));
      });

      test('should skip building when onlyUpload is true', () async {
        final context = BuildContext(
          flavorName: null,
          platform: 'android',
          buildArgs: '',
          onlyUpload: true,
        );

        final result = await androidBuilder.build(context);

        expect(result.success, true);
        expect(runCommandCalls, isEmpty);
      });

      test('should use FVM when buildMethod is fvm', () async {
        androidBuilder = AndroidBuilder(
          buildMethod: 'fvm',
          runCommand: mockRunCommand,
        );

        final context = BuildContext(
          flavorName: null,
          platform: 'android',
          buildArgs: '',
        );

        await androidBuilder.build(context);

        expect(runCommandCalls.first, startsWith('fvm fvm flutter build apk'));
      });

      test('should use Shorebird when buildMethod is shorebird', () async {
        androidBuilder = AndroidBuilder(
          buildMethod: 'shorebird',
          runCommand: mockRunCommand,
        );

        final context = BuildContext(
          flavorName: 'prod',
          platform: 'android',
          buildArgs: '--release',
        );

        await androidBuilder.build(context);

        expect(runCommandCalls.first, contains('shorebird release android'));
        expect(runCommandCalls, hasLength(1)); // Bundle skipped for shorebird
      });
    });
  });
}
