library build_and_send;

import 'dart:io';
import 'package:build_and_send/src/console_printer.dart';
import 'package:build_and_send/src/discord_notifier.dart';
import 'package:yaml/yaml.dart';

import 'build_config.dart';
import 'env_loader.dart';

final _printer = ConsolePrinter.slashes();

/// Class to run the build process
class BuildRunner {
  /// Build configuration
  final BuildConfig config;

  /// Platform to build
  /// This can be 'ios', 'android' or 'all'
  final String platform;

  /// Flavor name
  /// If provided, this will build the custom flavor
  final String? flavorName;

  /// Silent mode
  /// If true, no notification will be sent to discord
  final bool silent;

  /// No mention
  /// If true, no user will be mentioned in discord
  final bool noMention;

  /// Mention names
  /// Names of the users to mention in discord
  /// If not provided, all users will be mentioned
  /// This will only work if noMention is false
  /// If noMention is true, this will be ignored
  /// User should pass names acording in build_config.yaml file in discord: mention_users
  final List<String>? mentionNames;

  /// Verbose mode
  /// If true, all logs will be printed to console
  final bool verbose;

  /// Custom text
  /// Custom text to send in discord
  /// This will be sent along with the build details
  final String? customText;

  /// No pod sync
  /// If true, pod sync will be skipped
  /// This will only work for ios builds
  /// If you are having some issues with ios build, you can try manually sync pod files
  final bool noPodSync;

  /// Only upload
  /// If true, only the build artifacts will be uploaded
  /// This will not build the app
  final bool onlyUpload;

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
    this.onlyUpload = false,
  });

  String bundleUrl = '';
  String apkUrl = '';
  String uploadAccount = '';
  bool uploadedIpa = false;

  /// Run the build process
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
      final message = notifier.generateMessage(
        flavorName: flavorName,
        version: yaml['version'],
        apkUrl: apkUrl,
        bundleUrl: bundleUrl,
        sender: sender,
        customText: customText,
        uploadedIpa: uploadedIpa,
      );
      await notifier.notify(message,
          mention: !noMention, mentionNames: mentionNames);
    }
  }

  /// Build the android app
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
          'yes | shorebird release android --artifact=apk $flavorArgs $buildArgs';
    }
    if (!onlyUpload) {
      await _runCommand(
        command,
        progressMessage: 'Building APK',
        successMessage: 'APK built successfully',
        errorMessage: 'Failed to build APK',
        startMessage: 'Started building APK \n $command',
      );
    }
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
    if (command.isNotEmpty && !onlyUpload) {
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

  ///
  /// Build the ios app
  /// This method will build the ios app
  /// [flavor] Flavor configuration
  /// Returns a future
  /// Throws an error if the build fails
  /// If the build is successful, it will upload the IPA to App Store Connect
  ///
  Future<void> _buildIOS(FlavorConfig flavor) async {
    if (!Platform.isMacOS) return;
    var buildArgs = flavor.ios.buildArgs ?? '';
    var buildMethod = flavor.method;

    if (!onlyUpload) {
      var flavorArg = flavorName != null ? '--flavor $flavorName' : '';
      var targetArg =
          flavorName != null ? '--target lib/main_$flavorName.dart' : '';

      String command =
          'flutter build ipa --release $flavorArg $targetArg $buildArgs';
      if (buildMethod == 'fvm') {
        command = 'fvm $command';
      } else if (buildMethod == 'shorebird') {
        command =
            'yes | shorebird release ios $targetArg $flavorArg $buildArgs';
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
    }
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
    await _runCommand(
      uploadCommand,
      progressMessage: 'Uploading IPA to App Store Connect',
      onRun: (p0) {
        if (p0.exitCode == 0) {
          uploadedIpa = true;
        }
      },
      successMessage: 'Uploaded IPA to App Store Connect',
    );

    if (!uploadedIpa) {
      ConsolePrinter.writeError('Failed to upload IPA to App Store Connect',
          shouldExit: false);
    }
  }

  /// Upload file to GCloud
  /// This method will upload a file to GCloud
  /// [gcloud] GCloud configuration
  /// [path] Path to the file
  /// [filename] Name of the file
  /// Returns the URL of the uploaded file
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
    await _runCommand(command,
        progressMessage: 'Uploading $path$filename',
        successMessage: 'Uploaded $filename',
        errorMessage: 'Failed to upload $filename to gs://$bucket/$appId/');
    final url = 'https://storage.googleapis.com/$bucket/$appId/$filename';
    await _runCommand(
      'gsutil acl ch -u AllUsers:R gs://$bucket/$appId/$filename',
      successMessage: 'File made public at \n$url',
      errorMessage: 'Failed to make file public',
    );

    return url;
  }

  /// Run a command
  /// This method will run a command in the terminal
  /// and print the output to the console
  /// [command] Command to run
  /// [startMessage] Message to print before starting the command
  /// [errorMessage] Message to print if the command fails
  /// [successMessage] Message to print if the command is successful
  /// [progressMessage] Message to print while the command is running
  /// [onRun] Function to run after the command is run
  /// Returns a future
  /// Throws an error if the command fails
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
          if (verbose) {
            print(text);
          }
        });
        final err = [];
        process.stderr.listen((event) {
          final text = stderr.encoding.decode(event);
          err.add(text);
          if (verbose) {
            print(text);
          }
        });
        final exitCode = await process.exitCode;
        result = ProcessResult(
          process.pid,
          exitCode,
          out.lastOrNull,
          err.lastOrNull,
        );

        if (exitCode < 0) {
          throw Exception('Failed to run command: $command');
        } else {
          onRun?.call(result);
          ConsolePrinter.writeGreen(
              successMessage ?? 'Command completed successfully');
        }
      } catch (e) {
        ConsolePrinter.writeError(
            errorMessage ?? 'Failed to run command: $command');
        ConsolePrinter.writeError('Error: $e');
      } finally {
        process?.kill();
      }
    }

    if (progressMessage != null) {
      await _printer.writeProgress(progressMessage, run: () async {
        await runCommand();
      });
    } else {
      await runCommand();
    }
  }

  /// Set gcloud configurations
  /// This method will get the current gcloud authenticated account then
  /// if the current account does not match the required account, it will
  /// authenticate with the required account
  /// Then it will set the project id to the required project id
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
