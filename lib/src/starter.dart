library build_and_send;

import 'package:args/args.dart';
import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/build_runner.dart';
import 'package:build_and_send/src/console_printer.dart';
import 'package:build_and_send/src/constants.dart';
import 'package:build_and_send/src/env_loader.dart';
import 'package:build_and_send/src/logger.dart';
import 'package:build_and_send/src/validation/config_validator.dart';
import 'package:build_and_send/src/validation/input_validator.dart';

/// Starter class to start the build process
/// This class will parse the arguments and start the build process
class Starter {
  /// Start the build process
  static Future<void> start(List<String> args) async {
    final parser = ArgParser()
      ..addOption(
        'platform',
        abbr: 'p',
        allowed: ['android', 'ios', 'all'],
        defaultsTo: 'all',
        help:
            'Platform to build. Can be either android, ios or all. Default is all',
      )
      ..addOption(
        'flavor',
        abbr: 'f',
        help:
            'Flavor to build. If not provided, default flavor will be built. Must be configured in $buildConfigFile',
      )
      ..addFlag(
        'silent',
        abbr: 's',
        help:
            'Silent mode. Won\'t send any notification to discord even if configured',
      )
      ..addFlag(
        'no-mention',
        abbr: 'n',
        help:
            'Don\'t mention any user in discord when sending notification, even if configured. If this flag is not provided, all users configured will be mentioned',
      )
      ..addOption(
        'mention',
        abbr: 'm',
        help:
            'Mention specific users in discord when sending notification. Provide comma separated names. If not provided, all users configured will be mentioned. see $buildConfigFile'
            ' example for mentionUsers [command -m user1,user2], in .yaml file mentionUsers: user1:1234567890,user2:0987654321',
      )
      ..addFlag('verbose',
          abbr: 'v', help: 'Verbose mode. Will print all logs to console')
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addFlag('only-upload',
          help:
              'Only upload ipa (if ios) or apk (if android) or both (if -p not provided), ipa to testflight and apk/bundle to gcloud')
      ..addFlag('no-pod-sync',
          help:
              'If you are having some issues with ios build, you can try manually sync pod files. This flag will skip pod install step')
      ..addOption('text', abbr: 't', help: 'Custom text to send in discord');

    final argResults = parser.parse(args);

    if (argResults['help']) {
      print(parser.usage);
      return;
    }

    final platform = argResults['platform'];
    final flavor = argResults['flavor'];
    final silent = argResults['silent'];
    final noMention = argResults['no-mention'];
    final mention =
        argResults['mention']?.split(',')?.whereType<String>()?.toList();
    final verbose = argResults['verbose'];
    final customText = (argResults['text'] ?? '').toString();
    final noPodSync = argResults.wasParsed('no-pod-sync') ? false : true;
    final onlyUpload = argResults.wasParsed('only-upload') ? true : false;

    // Initialize logger with verbose mode
    Logger.init(verbose: verbose);
    Logger.startSection('Build and Send - Initialization');
    Logger.config('Platform', platform);
    Logger.config('Flavor', flavor ?? 'default');
    Logger.config('Silent mode', silent);
    Logger.config('No mention', noMention);
    Logger.config('Mention users', mention?.join(', ') ?? 'none');
    Logger.config('Verbose mode', verbose);
    Logger.config('Custom text', customText.isNotEmpty ? customText : 'none');
    Logger.config('No pod sync', noPodSync);
    Logger.config('Only upload', onlyUpload);

    // Validate input arguments
    Logger.step('Validating input arguments');
    try {
      InputValidator.validatePlatform(platform);
      InputValidator.validateFlavorName(flavor);
      InputValidator.validateMentionNames(mention);
      InputValidator.validateCustomText(customText);
      Logger.success('Input validation passed');
    } on ValidationException catch (e) {
      Logger.error('Input validation failed: ${e.message}');
      ConsolePrinter.writeError('Input validation failed: ${e.message}',
          shouldExit: true);
      return;
    }

    Logger.step('Loading environment and configuration');
    EnvLoader.load(envFile);
    Logger.debug('Environment loaded from $envFile');
    final config = BuildConfig.load(buildConfigFile);
    Logger.debug('Configuration loaded from $buildConfigFile');

    // Validate and sanitize configuration
    Logger.step('Validating build configuration');
    try {
      ConfigValidator.validateBuildConfig(config);
      Logger.success('Configuration validation passed');
      // Note: We could sanitize config here but it might change behavior
      // For now we just validate and let the original config through
    } on ValidationException catch (e) {
      Logger.error('Configuration validation failed: ${e.message}');
      ConsolePrinter.writeError('Configuration validation failed: ${e.message}',
          shouldExit: true);
      return;
    }

    Logger.endSection('initialization complete');
    Logger.startSection('Build Runner Setup');
    Logger.info('Creating BuildRunner instance');
    final runner = BuildRunner(
      config: config,
      platform: platform,
      flavorName: flavor,
      silent: silent,
      noMention: noMention,
      mentionNames: mention,
      verbose: verbose,
      customText: customText,
      noPodSync: noPodSync,
      onlyUpload: onlyUpload,
    );

    Logger.endSection();
    Logger.startSection('Build Process Execution');
    await runner.run();
    Logger.endSection('build process completed');
  }
}
