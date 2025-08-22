import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/notifiers/discord_notifier.dart';
import 'package:build_and_send/src/notifiers/notification_service.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationService', () {
    test('should create DiscordNotifier when discord config is provided', () {
      final discordConfig = DiscordConfig(
        webhookUrl: 'https://discord.com/webhook/test',
        channelId: '123456789',
        mentionUsers: {'user1': '111', 'user2': '222'},
      );
      final buildConfig = BuildConfig(
        method: 'default',
        android: AndroidConfig(
          apkPath: 'build/app/outputs/flutter-apk',
          bundlePath: 'build/app/outputs/bundle/release',
          apkName: 'app.apk',
          bundleName: 'app.aab',
        ),
        ios: IosConfig(),
        flavors: {},
        discord: discordConfig,
      );

      final notifier = NotificationService.create(buildConfig);

      expect(notifier, isA<DiscordNotifier>());
    });

    test('should return null when no notification config is provided', () {
      final buildConfig = BuildConfig(
        method: 'default',
        android: AndroidConfig(
          apkPath: 'build/app/outputs/flutter-apk',
          bundlePath: 'build/app/outputs/bundle/release',
          apkName: 'app.apk',
          bundleName: 'app.aab',
        ),
        ios: IosConfig(),
        flavors: {},
        discord: null,
      );

      final notifier = NotificationService.create(buildConfig);

      expect(notifier, isNull);
    });
  });
}
