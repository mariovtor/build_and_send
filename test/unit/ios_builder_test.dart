import 'dart:io';

import 'package:build_and_send/src/builders/builder.dart';
import 'package:build_and_send/src/builders/ios_builder.dart';
import 'package:test/test.dart';

void main() {
  group('IOSBuilder', () {
    late IOSBuilder iosBuilder;
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
      iosBuilder = IOSBuilder(
        buildMethod: 'default',
        noPodSync: false, // Skip pod sync for tests
        verbose: false,
        runCommand: mockRunCommand,
      );
    });

    group('build', () {
      test('should return failure on non-macOS platforms', () async {
        // This test will only pass on non-macOS systems
        final context = BuildContext(
          flavorName: 'dev',
          platform: 'ios',
          buildArgs: '',
        );

        final result = await iosBuilder.build(context);

        if (!Platform.isMacOS) {
          expect(result.success, false);
          expect(
              result.error, contains('iOS builds are only supported on macOS'));
        } else {
          // On macOS, it should succeed
          expect(result.success, true);
        }
      });

      test('should skip building when onlyUpload is true', () async {
        final context = BuildContext(
          flavorName: null,
          platform: 'ios',
          buildArgs: '',
          onlyUpload: true,
        );

        final result = await iosBuilder.build(context);

        if (Platform.isMacOS) {
          expect(result.success, true);
          expect(runCommandCalls, isEmpty);
        }
      });

      test('should run pod sync when noPodSync is true', () async {
        iosBuilder = IOSBuilder(
          buildMethod: 'default',
          noPodSync: true,
          runCommand: mockRunCommand,
        );

        final context = BuildContext(
          flavorName: null,
          platform: 'ios',
          buildArgs: '',
        );

        await iosBuilder.build(context);

        if (Platform.isMacOS) {
          expect(runCommandCalls.first, contains('pod install'));
        }
      });

      test('should build with flavor and target args', () async {
        final context = BuildContext(
          flavorName: 'dev',
          platform: 'ios',
          buildArgs: '--verbose',
        );

        await iosBuilder.build(context);

        if (Platform.isMacOS) {
          final buildCommand = runCommandCalls.last;
          expect(buildCommand, contains('--flavor dev'));
          expect(buildCommand, contains('--target lib/main_dev.dart'));
          expect(buildCommand, contains('--verbose'));
        }
      });
    });
  });
}
