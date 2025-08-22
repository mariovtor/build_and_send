library build_and_send;

import 'dart:io';

import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/console_printer.dart';
import 'package:build_and_send/src/logger.dart';
import 'package:build_and_send/src/uploaders/uploader.dart';

typedef RunCommandFunction = Future<void> Function(
  String command, {
  String? startMessage,
  String? errorMessage,
  String? successMessage,
  String? progressMessage,
  Function(ProcessResult)? onRun,
});

class GCloudUploader implements Uploader {
  final GCloudConfig gcloudConfig;
  final String uploadAccount;
  final bool verbose;
  final RunCommandFunction _runCommand;

  GCloudUploader({
    required this.gcloudConfig,
    required this.uploadAccount,
    this.verbose = false,
    RunCommandFunction? runCommand,
  }) : _runCommand = runCommand ?? _defaultRunCommand;

  @override
  Future<String> upload(UploadContext context) async {
    Logger.startSection('GCloud Upload');
    Logger.debug('Upload account: $uploadAccount');
    Logger.debug('Bucket: ${gcloudConfig.bucket}');
    Logger.debug('App ID: ${gcloudConfig.appId}');
    Logger.debug('File: ${context.fileName}');
    Logger.debug('Path: ${context.filePath}');

    if (uploadAccount.isEmpty) {
      Logger.warning('Skipping upload to GCloud, no upload account provided');
      ConsolePrinter.writeWhite(
          'Skipping upload to GCloud, no upload account provided');
      Logger.endSection();
      return '';
    }

    var bucket = gcloudConfig.bucket;
    var appId = gcloudConfig.appId;

    var path = context.filePath;
    if (!path.endsWith('/')) {
      path = '$path/';
    }

    Logger.step('Checking file existence');

    ///check if file exists
    if (!File('$path${context.fileName}').existsSync()) {
      Logger.error('File $path${context.fileName} does not exist');
      ConsolePrinter.writeError('File $path${context.fileName} does not exist',
          shouldExit: false);
      Logger.endSection();
      return '';
    }

    Logger.step('Uploading file to Google Cloud Storage');
    var command = 'gsutil cp $path${context.fileName} gs://$bucket/$appId/';
    Logger.command(command);
    await _runCommand(command,
        progressMessage: 'Uploading $path${context.fileName}',
        successMessage: 'Uploaded ${context.fileName}',
        errorMessage:
            'Failed to upload ${context.fileName} to gs://$bucket/$appId/');

    Logger.step('Making file public');
    final url =
        'https://storage.googleapis.com/$bucket/$appId/${context.fileName}';
    Logger.debug('Public URL will be: $url');
    await _runCommand(
      'gsutil acl ch -u AllUsers:R gs://$bucket/$appId/${context.fileName}',
      successMessage: 'File made public at \n$url',
      errorMessage: 'Failed to make file public',
    );

    Logger.success('File uploaded successfully');
    Logger.endSection();
    return url;
  }

  /// Set gcloud configurations
  /// This method will get the current gcloud authenticated account then
  /// if the current account does not match the required account, it will
  /// authenticate with the required account
  /// Then it will set the project id to the required project id
  Future<void> setGCloudConfigs() async {
    Logger.step('Setting up GCloud configurations');
    if (uploadAccount.isEmpty) {
      Logger.warning('No upload account provided');
      ConsolePrinter.writeWhite('No upload account provided');
      return;
    }

    String loggedUploadAccount = '';

    Logger.debug('Getting current GCloud authenticated account');

    ///get current gcloud authenticated account
    await _runCommand('gcloud config get-value account', onRun: (r) {
      if (r.exitCode == 0) {
        loggedUploadAccount = r.stdout.toString().trim();
      }
    });

    Logger.debug('Current account: $loggedUploadAccount');
    Logger.debug('Required account: $uploadAccount');

    if (loggedUploadAccount != uploadAccount) {
      Logger.warning('Account mismatch detected, need to authenticate');
      ConsolePrinter.writeWhite(
          ' The current authenticated account ($loggedUploadAccount) does not match the required account ($uploadAccount). Please authenticate with the correct account');
      await Future.delayed(Duration(seconds: 2));

      Logger.step('Authenticating with correct account');

      ///set account to gcloud
      await _runCommand('gcloud auth login $uploadAccount');
    } else {
      Logger.debug('Account matches, no authentication needed');
    }

    Logger.step('Setting project configuration');

    ///set project id and account to gcloud
    await _runCommand('gcloud config set project ${gcloudConfig.appId}');
  }

  static Future<void> _defaultRunCommand(
    String command, {
    String? startMessage,
    String? errorMessage,
    String? successMessage,
    String? progressMessage,
    Function(ProcessResult)? onRun,
  }) async {
    Logger.debug('Executing GCloud command: $command');
    // Original _runCommand logic
    if (startMessage != null) {
      ConsolePrinter.writeWhite(startMessage);
    }
    Future<void> runCommand() async {
      ProcessResult? result;
      final workingDirectory = Directory.current.path;

      Process? process;

      try {
        process = await Process.start(
          'sh',
          ['-c', command],
          runInShell: true,
          workingDirectory: workingDirectory,
        );
        final out = [];
        process.stdout.listen((event) {
          final text = stdout.encoding.decode(event);
          out.add(text);
        });
        final err = [];
        process.stderr.listen((event) {
          final text = stderr.encoding.decode(event);
          err.add(text);
        });
        final exitCode = await process.exitCode;
        result = ProcessResult(
          process.pid,
          exitCode,
          out.lastOrNull,
          err.lastOrNull,
        );

        if (exitCode != 0) {
          Logger.error('Command failed with exit code $exitCode');
          if (out.isNotEmpty) {
            Logger.info('Command stdout:');
            ConsolePrinter.writeWhite(out.join().trim());
          }
          if (err.isNotEmpty) {
            Logger.error('Command stderr:');
            ConsolePrinter.writeError(err.join().trim(), shouldExit: false);
          }
          throw Exception(
              'Command failed with exit code $exitCode: ${err.join().trim()}');
        } else {
          onRun?.call(result);
          ConsolePrinter.writeGreen(
              successMessage ?? 'Command completed successfully');
        }
      } catch (e) {
        Logger.error('Exception during command execution: $e');
        ConsolePrinter.writeError(
            errorMessage ?? 'Failed to run command: $command');
        if (result != null) {
          if (result.stdout.toString().isNotEmpty) {
            ConsolePrinter.writeWhite('Output: ${result.stdout}');
          }
          if (result.stderr.toString().isNotEmpty) {
            ConsolePrinter.writeError('Error output: ${result.stderr}',
                shouldExit: false);
          }
        }
        rethrow;
      }
    }

    if (progressMessage != null) {
      await ConsolePrinter.slashes().writeProgress(progressMessage,
          run: () async {
        await runCommand();
      });
    } else {
      await runCommand();
    }
  }
}
