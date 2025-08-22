library build_and_send;

import 'dart:io';

import 'package:build_and_send/src/builders/build_service.dart';
import 'package:build_and_send/src/builders/builder.dart';
import 'package:build_and_send/src/console_printer.dart';
import 'package:build_and_send/src/logger.dart';
import 'package:build_and_send/src/notifiers/notification_service.dart';
import 'package:build_and_send/src/notifiers/notifier.dart';
import 'package:build_and_send/src/uploaders/upload_service.dart';
import 'package:build_and_send/src/uploaders/uploader.dart';
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
    Logger.info('Starting build runner with platform: $platform');
    final usingCustomFlavor =
        flavorName != null && config.flavors.containsKey(flavorName);
    Logger.config('Using custom flavor', usingCustomFlavor);
    Logger.config('Flavor name', flavorName ?? 'default');
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

    Logger.step('Determining build targets');
    if (platform == 'ios' || platform == 'all') {
      Logger.info('iOS build target selected');
      await _buildIOSWithNewService(flavor!);
    }
    if (platform == 'android' || platform == 'all') {
      Logger.info('Android build target selected');
      await _buildAndroidWithNewService(flavor!);
    }

    Logger.startSection('Post-build Processing');
    if (config.discord?.webhookUrl.isNotEmpty != true) {
      Logger.info('Discord notifications disabled or not configured');
      Logger.endSection('no notifications');
      return;
    }

    if (!silent && config.discord?.webhookUrl.isNotEmpty == true) {
      Logger.step('Preparing Discord notification');
      if (bundleUrl.isEmpty && apkUrl.isEmpty && uploadedIpa == false) {
        Logger.warning('No build artifacts found to send to Discord');
        ConsolePrinter.writeError(
            'No build artifacts found to send to Discord');
        return;
      }
      final yaml = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
      final sender = EnvLoader.get('DISCORD_SENDER_ID') ?? uploadAccount;
      Logger.config('Discord sender', sender);
      Logger.config('App version', yaml['version']);

      // Use new notification service
      Logger.step('Creating notification service');
      final notifier = NotificationService.create(config);
      if (notifier != null) {
        Logger.debug('Creating notification context');
        final context = NotificationContext(
          flavorName: flavorName,
          version: yaml['version'],
          apkUrl: apkUrl,
          bundleUrl: bundleUrl,
          sender: sender,
          uploadedIpa: uploadedIpa,
          customText: customText,
          mention: !noMention,
          mentionNames: mentionNames,
        );
        await notifier.notify(context);
      }
    }
  }

  /// Build Android using new AndroidBuilder service
  Future<void> _buildAndroidWithNewService(FlavorConfig flavor) async {
    Logger.startSection('Android Build Process');
    Logger.config('Android build args', flavor.android.buildArgs ?? 'none');
    Logger.config('APK path', flavor.android.apkPath);
    Logger.config('Bundle path', flavor.android.bundlePath);

    // Use new AndroidBuilder
    Logger.step('Creating Android builder');
    final builder = BuildService.createAndroidBuilder(
      flavor: flavor,
      verbose: verbose,
    );

    Logger.step('Preparing build context');
    final buildContext = BuildContext(
      flavorName: flavorName,
      platform: 'android',
      buildArgs: flavor.android.buildArgs ?? '',
      onlyUpload: onlyUpload,
    );

    Logger.step('Executing Android build');
    final result = await builder.build(buildContext);
    if (!result.success) {
      Logger.error('Android build failed: ${result.error}');
      ConsolePrinter.writeError('Android build failed: ${result.error}');
      return;
    }
    Logger.success('Android build completed successfully');

    // Handle uploads using existing upload service
    if (flavor.android.gcloud != null) {
      Logger.step('Preparing uploads to GCloud');
      Logger.config('Upload account', uploadAccount);
      final uploader = UploadService.create(
        config: config,
        uploadAccount: uploadAccount,
        verbose: verbose,
      );
      if (uploader != null) {
        Logger.step('Uploading APK');
        apkUrl = await uploader.upload(
          UploadContext(
            filePath: flavor.android.apkPath,
            fileName: flavor.android.apkName,
          ),
        );
        Logger.debug('APK upload completed, URL: $apkUrl');

        Logger.step('Uploading Bundle');
        bundleUrl = await uploader.upload(
          UploadContext(
            filePath: flavor.android.bundlePath,
            fileName: flavor.android.bundleName,
          ),
        );
        Logger.debug('Bundle upload completed, URL: $bundleUrl');
      } else {
        Logger.warning('No uploader available for GCloud');
      }
    } else {
      Logger.info('No GCloud configuration found, skipping uploads');
    }
    Logger.endSection('Android build process completed');
  }

  /// Build iOS using new IOSBuilder service
  Future<void> _buildIOSWithNewService(FlavorConfig flavor) async {
    if (!Platform.isMacOS) {
      Logger.warning('iOS builds are only supported on macOS, skipping');
      return;
    }

    Logger.startSection('iOS Build Process');
    Logger.config('iOS build args', flavor.ios.buildArgs ?? 'none');
    Logger.config('IPA name', flavor.ios.ipaName ?? 'default');
    Logger.config('No pod sync', noPodSync);

    // Use new IOSBuilder
    Logger.step('Creating iOS builder');
    final builder = BuildService.createIOSBuilder(
      flavor: flavor,
      noPodSync: noPodSync,
      verbose: verbose,
    );

    Logger.step('Preparing build context');
    final buildContext = BuildContext(
      flavorName: flavorName,
      platform: 'ios',
      buildArgs: flavor.ios.buildArgs ?? '',
      onlyUpload: onlyUpload,
    );

    Logger.step('Executing iOS build');
    final result = await builder.build(buildContext);
    if (!result.success) {
      Logger.error('iOS build failed: ${result.error}');
      ConsolePrinter.writeError('iOS build failed: ${result.error}');
      return;
    }
    Logger.success('iOS build completed successfully');

    // Handle TestFlight upload (keep existing logic for now)
    Logger.step('Preparing TestFlight upload');
    await _uploadToTestFlight(flavor);
    Logger.endSection('iOS build process completed');
  }

  /// Upload IPA to TestFlight (extracted from original _buildIOS)
  Future<void> _uploadToTestFlight(FlavorConfig flavor) async {
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
}
