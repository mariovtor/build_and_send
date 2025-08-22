import 'dart:io';

import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/uploaders/gcloud_uploader.dart';
import 'package:build_and_send/src/uploaders/uploader.dart';
import 'package:test/test.dart';

void main() {
  group('GCloudUploader', () {
    late GCloudUploader gCloudUploader;
    late GCloudConfig mockGCloudConfig;
    late String mockUploadAccount;

    // Simple function variables to track calls
    var runCommandCalls = <String>[];
    ProcessResult? mockProcessResult;

    Future<void> mockRunCommand(
      String command, {
      String? startMessage,
      String? errorMessage,
      String? successMessage,
      String? progressMessage,
      Function(ProcessResult)? onRun,
    }) async {
      runCommandCalls.add(command);
      if (onRun != null && mockProcessResult != null) {
        onRun(mockProcessResult!);
      }
    }

    setUp(() {
      mockGCloudConfig =
          GCloudConfig(bucket: 'test-bucket', appId: 'test-app-id');
      mockUploadAccount = 'test@example.com';
      runCommandCalls.clear();
      mockProcessResult = null;

      gCloudUploader = GCloudUploader(
        gcloudConfig: mockGCloudConfig,
        uploadAccount: mockUploadAccount,
        verbose: false,
        runCommand: mockRunCommand,
      );
    });

    group('setGCloudConfigs', () {
      test('should authenticate and set project if accounts do not match',
          () async {
        // Set up mock to return different account
        mockProcessResult = ProcessResult(1, 0, 'other@example.com\n', '');

        await gCloudUploader.setGCloudConfigs();

        expect(runCommandCalls, contains('gcloud config get-value account'));
        expect(
            runCommandCalls, contains('gcloud auth login $mockUploadAccount'));
        expect(runCommandCalls,
            contains('gcloud config set project ${mockGCloudConfig.appId}'));
      });

      test('should not authenticate if accounts match but still set project',
          () async {
        // Set up mock to return matching account
        mockProcessResult = ProcessResult(1, 0, '$mockUploadAccount\n', '');

        await gCloudUploader.setGCloudConfigs();

        expect(runCommandCalls, contains('gcloud config get-value account'));
        expect(runCommandCalls,
            isNot(contains('gcloud auth login $mockUploadAccount')));
        // Project should still be set even if accounts match
        expect(runCommandCalls,
            contains('gcloud config set project ${mockGCloudConfig.appId}'));
      });
    });

    group('upload', () {
      test('should return empty string if upload account is empty', () async {
        gCloudUploader = GCloudUploader(
          gcloudConfig: mockGCloudConfig,
          uploadAccount: '',
          verbose: false,
          runCommand: mockRunCommand,
        );
        final uploadContext =
            UploadContext(filePath: 'path/to/file', fileName: 'app.apk');
        final result = await gCloudUploader.upload(uploadContext);
        expect(result, '');
      });

      test('should return empty string if file does not exist', () async {
        final uploadContext =
            UploadContext(filePath: 'nonexistent/path', fileName: 'app.apk');
        final result = await gCloudUploader.upload(uploadContext);
        expect(result, '');
      });
    });
  });
}
