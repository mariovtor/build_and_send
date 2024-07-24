library build_and_send;

import 'package:args/args.dart';
import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/build_runner.dart';
import 'package:build_and_send/src/constants.dart';
import 'package:build_and_send/src/env_loader.dart';

class Starter {
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
      ..addFlag('no-pod-sync',
          help:
              'If you are having some issues with ios build, you can try manually sync pod files. This flag will skip pod install step')
      ..addFlag('text', abbr: 't', help: 'Custom text to send in discord');

    final argResults = parser.parse(args);

    if (argResults['help']) {
      print(parser.usage);
      return;
    }

    final platform = 'android';
    // argResults['platform'];
    final flavor = 'dev'; // argResults['flavor'];
    final silent = argResults['silent'];
    final noMention = argResults['no-mention'];
    final mention =
        argResults['mention']?.split(',')?.whereType<String>()?.toList();
    final verbose = argResults['verbose'];
    final customText = argResults['text']?.toString();
    final noPodSync = argResults.wasParsed('no-pod-sync') ? false : true;

    EnvLoader.load(envFile);
    final config = BuildConfig.load(buildConfigFile);

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
    );

    await runner.run();
  }
}
