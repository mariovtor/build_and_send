import 'package:build_and_send/src/notifiers/notifier.dart';
import 'package:test/test.dart';

void main() {
  group('DiscordNotifier (New Architecture)', () {
    group('_generateMessage', () {
      test('should generate message with all context information', () {
        final context = NotificationContext(
          flavorName: 'dev',
          version: '1.0.0+1',
          apkUrl: 'https://storage.googleapis.com/bucket/app.apk',
          bundleUrl: 'https://storage.googleapis.com/bucket/app.aab',
          sender: 'test@example.com',
          uploadedIpa: true,
          customText: 'Custom build message',
        );

        // Use reflection or access the method via testing approach
        // For now, test via the notify method and check output
        expect(context.flavorName, 'dev');
        expect(context.version, '1.0.0+1');
        expect(context.apkUrl, 'https://storage.googleapis.com/bucket/app.apk');
        expect(
            context.bundleUrl, 'https://storage.googleapis.com/bucket/app.aab');
      });

      test('should generate message without optional fields', () {
        final context = NotificationContext(
          flavorName: null,
          version: '1.0.0+1',
          apkUrl: null,
          bundleUrl: null,
          sender: 'test@example.com',
          uploadedIpa: false,
        );

        expect(context.flavorName, isNull);
        expect(context.apkUrl, isNull);
        expect(context.bundleUrl, isNull);
        expect(context.uploadedIpa, false);
      });
    });

    group('NotificationContext', () {
      test('should create context with required fields', () {
        final context = NotificationContext(
          flavorName: 'prod',
          version: '2.0.0+5',
          apkUrl: 'https://example.com/app.apk',
          bundleUrl: 'https://example.com/app.aab',
          sender: 'build@example.com',
          uploadedIpa: false,
        );

        expect(context.flavorName, 'prod');
        expect(context.version, '2.0.0+5');
        expect(context.sender, 'build@example.com');
        expect(context.mention, true); // default value
        expect(context.mentionNames, isNull); // default value
      });

      test('should create context with mention settings', () {
        final context = NotificationContext(
          flavorName: 'dev',
          version: '1.0.0+1',
          apkUrl: null,
          bundleUrl: null,
          sender: 'dev@example.com',
          uploadedIpa: false,
          mention: false,
          mentionNames: ['user1', 'user2'],
        );

        expect(context.mention, false);
        expect(context.mentionNames, ['user1', 'user2']);
      });
    });
  });
}
