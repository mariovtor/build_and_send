library build_and_send;

import 'dart:io';
import 'package:build_and_send/src/console_printer.dart';
import 'package:build_and_send/src/discord_notifier.dart';
import 'package:yaml/yaml.dart';

import 'build_config.dart';
import 'env_loader.dart';

final _printer = ConsolePrinter.slashes();

class BuildRunner {
  final BuildConfig config;
  final String platform;
  final String? flavorName;
  final bool silent;
  final bool noMention;
  final List<String>? mentionNames;
  final bool verbose;
  final String? customText;
  final bool noPodSync;

  BuildRunner({
    required this.config,
    required this.platform,
    this.customText,
    this.flavorName,
    this.silent = false,
    this.noMention = false,
    this.mentionNames,
    this.verbose = false,
    this.noPodSync = true,
  });

  String bundleUrl = '';
  String apkUrl = '';
  String uploadAccount = '';
  bool uploadedIpa = false;
  Future<void> run() async {
    final usingCustomFlavor =
        flavorName != null && config.flavors.containsKey(flavorName);
    var flavor = usingCustomFlavor
        ? config.flavors[flavorName!]
        : FlavorConfig(
            method: config.method,
            android: config.android,
            ios: config.ios,
          );

    if (flavor?.android.gcloud != null &&
        (platform == 'android' || platform == 'all')) {
      if (usingCustomFlavor) {
        uploadAccount =
            EnvLoader.get('${flavorName!.toUpperCase()}_UPLOAD_EMAIL') ??
                EnvLoader.get('ACCOUNT_EMAIL') ??
                '';
      } else {
        uploadAccount = EnvLoader.get('ACCOUNT_EMAIL') ?? '';
      }
    }

    if (platform == 'ios' || platform == 'all') {
      await _buildIOS(flavor!);
    }
    if (platform == 'android' || platform == 'all') {
      await _buildAndroid(flavor!);
    }

    if (config.discord?.webhookUrl.isNotEmpty != true) {
      return;
    }

    if (!silent && config.discord!.webhookUrl.isNotEmpty) {
      if (bundleUrl.isEmpty && apkUrl.isEmpty && uploadedIpa == false) {
        ConsolePrinter.writeError(
            'No build artifacts found to send to Discord');
        return;
      }
      final yaml = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;

      final sender = EnvLoader.get('DISCORD_SENDER_ID') ?? uploadAccount;
      final notifier = DiscordNotifier(config.discord!);
      final message = DiscordNotifier.generateMessage(
        flavorName: flavorName,
        version: yaml['version'],
        apkUrl: apkUrl,
        bundleUrl: bundleUrl,
        sender: sender,
        discordChannel: null,
        customText: customText,
        uploadedIpa: uploadedIpa,
      );
      await notifier.notify(message,
          mention: !noMention, mentionNames: mentionNames);
    }
  }

  Future<void> _buildAndroid(FlavorConfig flavor) async {
    final flavorArgs = flavorName != null ? '--flavor $flavorName' : '';
    var buildArgs = flavor.android.buildArgs ?? '';
    var buildMethod = flavor.method;

    if (flavor.android.gcloud != null) {
      await setGCloudConfigs(flavor.android.gcloud!.appId);
    }

    var command = 'flutter build apk $flavorArgs $buildArgs';
    if (buildMethod == 'fvm') {
      command = 'fvm $command';
    } else if (buildMethod == 'shorebird') {
      command =
          'shorebird release android --artifact apk $flavorArgs $buildArgs';
    }

    await _runCommand(
      command,
      progressMessage: 'Building APK',
      successMessage: 'APK built successfully',
      errorMessage: 'Failed to build APK',
      startMessage: 'Started building APK \n $command',
    );

    if (flavor.android.gcloud != null) {
      apkUrl = await _uploadToGCloud(
        flavor.android.gcloud!,
        path: flavor.android.apkPath,
        filename: flavor.android.apkName,
      );
    }

    command = 'flutter build appbundle $flavorArgs $buildArgs';
    if (buildMethod == 'fvm') {
      command = 'fvm $command';
    } else if (buildMethod == 'shorebird') {
      ///if shorebird is used, bundle was already built in the previous command
      command = '';
      // command = 'shorebird build appbundle $buildArgs';
    }
    if (command.isNotEmpty) {
      await _runCommand(
        command,
        progressMessage: 'Building Bundle',
        successMessage: 'Bundle built successfully',
        errorMessage: 'Failed to build Bundle',
        startMessage: 'Started building Bundle \n $command',
      );
    }

    if (flavor.android.gcloud != null) {
      bundleUrl = await _uploadToGCloud(flavor.android.gcloud!,
          path: flavor.android.bundlePath, filename: flavor.android.bundleName);
    }
  }

  Future<void> _buildIOS(FlavorConfig flavor) async {
    var buildArgs = flavor.ios.buildArgs ?? '';
    var buildMethod = flavor.method;

    var flavorArg = flavorName != null ? '--flavor $flavorName' : '';
    var targetArg =
        flavorName != null ? '--target lib/main_$flavorName.dart' : '';

    String command =
        'flutter build ipa --release $flavorArg $targetArg $buildArgs';
    if (buildMethod == 'fvm') {
      command = 'fvm $command';
    } else if (buildMethod == 'shorebird') {
      command = 'shorebird release ios $targetArg $flavorArg';
    }

    if (noPodSync) {
      String cleanCommand = '''
      cd ios
      pod deintegrate
      rm Podfile.lock
      rm -rf .symlinks
      pod install
      cd ..
      ''';
      await _runCommand(cleanCommand, progressMessage: 'Running Pod Sync');
    }

    await _runCommand(
      command,
      startMessage: 'Started building IPA',
      progressMessage: 'Building IPA',
    );

    var email = EnvLoader.get('APPLE_EMAIL');
    var appSpecificPassword = EnvLoader.get('APPLE_APP_SPECIFIC_PASSWORD');
    if (email?.isNotEmpty != true || appSpecificPassword?.isNotEmpty != true) {
      ConsolePrinter.writeWhite(
          'Apple email or app specific password not provided');
      ConsolePrinter.writeWhite(
          'Build completed successfully but IPA was not uploaded');
      return;
    }
    String ipaName = flavor.ios.ipaName ?? '';

    if (ipaName.isEmpty) {
      ///search ipa file in the build directory
      await _runCommand('ls build/ios/ipa',
          progressMessage: 'Searching IPA file', onRun: (result) {
        if (result.exitCode == 0) {
          final ipaFiles = result.stdout.toString().split('\n');
          if (ipaFiles.isNotEmpty) {
            ipaName =
                ipaFiles.where((e) => e.endsWith('.ipa')).firstOrNull ?? '';
          }
        }
      });
    }
    if (!File('build/ios/ipa/$ipaName').existsSync()) {
      ConsolePrinter.writeError('No IPA file found in build/ios/ipa',
          shouldExit: false);
      return;
    }

    var uploadCommand =
        'xcrun altool --upload-app -f "build/ios/ipa/$ipaName" -t ios -u "$email" -p "$appSpecificPassword"';
    await _runCommand(uploadCommand,
        progressMessage: 'Uploading IPA to App Store Connect', onRun: (p0) {
      if (p0.exitCode == 0) {
        uploadedIpa = true;
      }
    });

    if (uploadedIpa) {
      ConsolePrinter.writeGreen('Uploaded IPA to App Store Connect');
    } else {
      ConsolePrinter.writeError('Failed to upload IPA to App Store Connect',
          shouldExit: false);
    }
  }

  Future<String> _uploadToGCloud(
    GCloudConfig gcloud, {
    required String path,
    required String filename,
  }) async {
    if (uploadAccount.isEmpty) {
      ConsolePrinter.writeWhite(
          'Skipping upload to GCloud, no upload account provided');
      return '';
    }

    var bucket = gcloud.bucket;
    var appId = gcloud.appId;

    if (!path.endsWith('/')) {
      path = '$path/';
    }

    ///check if file exists
    if (!File('$path$filename').existsSync()) {
      ConsolePrinter.writeError('File $path$filename does not exist',
          shouldExit: false);
      return '';
    }

    var command = 'gsutil cp $path$filename gs://$bucket/$appId/';
    await _runCommand(command, progressMessage: 'Uploading $path$filename');
    await _runCommand(
        'gsutil acl ch -u AllUsers:R gs://$bucket/$appId/$filename');
    final url = 'https://storage.googleapis.com/$bucket/$appId/$filename';
    ConsolePrinter.writeGreen('Uploaded $filename to $url');
    return url;
  }

  Future<void> _runCommand(
    String command, {
    String? startMessage,
    String? errorMessage,
    String? successMessage,
    String? progressMessage,
    Function(ProcessResult)? onRun,
  }) async {
    if (verbose) {
      print('Running: $command');
    }
    if (startMessage != null) {
      ConsolePrinter.writeWhite(startMessage);
    }
    ProcessResult? result;
    final workingDirectory = Directory.current.path;
    if (progressMessage != null) {
      await _printer.writeProgress(progressMessage, run: () async {
        result = await Process.run(
          'sh',
          ['-c', command],
          runInShell: true,
          workingDirectory: workingDirectory,
        );
      });
      if (result != null) {
        onRun?.call(result!);
      }
      if (result?.exitCode != 0) {
        ConsolePrinter.writeError(errorMessage ?? 'Failed to run command:',
            shouldExit: false);

        ConsolePrinter.writeError('\n$command\n', shouldExit: false);
        ConsolePrinter.writeError('Error: ${result?.stderr}');
      } else {
        ConsolePrinter.writeGreen(
            successMessage ?? 'Command completed successfully');
      }
    } else {
      result = await Process.run(
        'sh',
        ['-c', command],
        runInShell: true,
        workingDirectory: workingDirectory,
      );
      onRun?.call(result);
      if (result.exitCode != 0) {
        ConsolePrinter.writeError(
            errorMessage ?? 'Failed to run command: $command');
      } else {
        ConsolePrinter.writeGreen(
            successMessage ?? 'Command completed successfully');
      }
    }

    if (verbose) {
      print(result?.stdout);
      print(result?.stderr);
    }
  }

  Future<void> setGCloudConfigs(String appId) async {
    if (uploadAccount.isEmpty) {
      ConsolePrinter.writeWhite('No upload account provided');
      return;
    }

    String loggedUploadAccount = '';

    ///get current gcloud authenticated account
    await _runCommand('gcloud config get-value account', onRun: (r) {
      if (r.exitCode == 0) {
        loggedUploadAccount = r.stdout.toString().trim();
      }
    });

    if (loggedUploadAccount != uploadAccount) {
      ConsolePrinter.writeWhite(
          ' The current authenticated account ($loggedUploadAccount) does not match the required account ($uploadAccount). Please authenticate with the correct account');
      await Future.delayed(Duration(seconds: 2));

      ///set account to gcloud
      await _runCommand('gcloud auth login $uploadAccount');
    }

    ///set project id and account to gcloud
    await _runCommand('gcloud config set project $appId');
  }
}
