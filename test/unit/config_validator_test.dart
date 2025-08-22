library build_and_send;

import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/validation/config_validator.dart';
import 'package:build_and_send/src/validation/input_validator.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigValidator', () {
    group('validateBuildConfig', () {
      test('should validate complete valid config', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
            gcloud: GCloudConfig(
              bucket: 'test-bucket',
              appId: 'com.example.app',
            ),
          ),
          ios: IosConfig(
            ipaName: 'Runner.ipa',
          ),
          flavors: {
            'dev': FlavorConfig(
              method: 'default',
              android: AndroidConfig(
                apkPath: 'build/app/outputs/flutter-apk/',
                bundlePath: 'build/app/outputs/bundle/release',
                apkName: 'app-dev-release.apk',
                bundleName: 'app-dev-release.aab',
              ),
              ios: IosConfig(),
            ),
          },
          discord: DiscordConfig(
            webhookUrl: 'https://discord.com/api/webhooks/123/abc',
            mentionUsers: {'user1': '123456789'},
            showVersion: true,
            showFlavor: true,
          ),
        );

        expect(
            () => ConfigValidator.validateBuildConfig(config), returnsNormally);
      });

      test('should reject invalid build method', () {
        final config = BuildConfig(
          method: 'invalid-method',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
          ),
          ios: IosConfig(),
          flavors: {},
          discord: null,
        );

        expect(() => ConfigValidator.validateBuildConfig(config),
            throwsA(isA<ValidationException>()));
      });

      test('should reject empty Android config fields', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: '',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
          ),
          ios: IosConfig(),
          flavors: {},
          discord: null,
        );

        expect(() => ConfigValidator.validateBuildConfig(config),
            throwsA(isA<ValidationException>()));
      });

      test('should reject invalid GCloud bucket name', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
            gcloud: GCloudConfig(
              bucket: 'INVALID_BUCKET_NAME',
              appId: 'com.example.app',
            ),
          ),
          ios: IosConfig(),
          flavors: {},
          discord: null,
        );

        expect(() => ConfigValidator.validateBuildConfig(config),
            throwsA(isA<ValidationException>()));
      });

      test('should reject invalid Discord webhook URL', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
          ),
          ios: IosConfig(),
          flavors: {},
          discord: DiscordConfig(
            webhookUrl: 'not-a-valid-url',
            showVersion: true,
            showFlavor: true,
          ),
        );

        expect(() => ConfigValidator.validateBuildConfig(config),
            throwsA(isA<ValidationException>()));
      });

      test('should reject invalid flavor names', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
          ),
          ios: IosConfig(),
          flavors: {
            'invalid-flavor-name': FlavorConfig(
              method: 'default',
              android: AndroidConfig(
                apkPath: 'build/app/outputs/flutter-apk/',
                bundlePath: 'build/app/outputs/bundle/release',
                apkName: 'app-release.apk',
                bundleName: 'app-release.aab',
              ),
              ios: IosConfig(),
            ),
          },
          discord: null,
        );

        expect(() => ConfigValidator.validateBuildConfig(config),
            throwsA(isA<ValidationException>()));
      });
    });

    group('sanitizeConfig', () {
      test('should sanitize all string fields in config', () {
        final config = BuildConfig(
          method: 'default<script>',
          android: AndroidConfig(
            buildArgs: '--target="malicious"',
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release<test>.apk',
            bundleName: 'app-release.aab',
            gcloud: GCloudConfig(
              bucket: 'test-bucket<script>',
              appId: 'com.example.app',
            ),
          ),
          ios: IosConfig(
            buildArgs: '--config="dangerous"',
            ipaName: 'Runner<test>.ipa',
          ),
          flavors: {
            'dev<script>': FlavorConfig(
              method: 'fvm<test>',
              android: AndroidConfig(
                apkPath: 'build/app/outputs/flutter-apk/',
                bundlePath: 'build/app/outputs/bundle/release',
                apkName: 'app-release.apk',
                bundleName: 'app-release.aab',
              ),
              ios: IosConfig(),
            ),
          },
          discord: DiscordConfig(
            webhookUrl: 'https://discord.com/api/webhooks/123/abc<script>',
            channelId: '123456789<test>',
            mentionUsers: {'user<script>': '123456789<test>'},
            showVersion: true,
            showFlavor: true,
          ),
        );

        final sanitized = ConfigValidator.sanitizeConfig(config);

        expect(sanitized.method, equals('defaultscript'));
        expect(sanitized.android.buildArgs, equals('--target=malicious'));
        expect(sanitized.android.apkName, equals('app-releasetest.apk'));
        expect(sanitized.android.gcloud!.bucket, equals('test-bucketscript'));
        expect(sanitized.ios.buildArgs, equals('--config=dangerous'));
        expect(sanitized.ios.ipaName, equals('Runnertest.ipa'));
        expect(sanitized.flavors.keys.first, equals('devscript'));
        expect(sanitized.discord!.webhookUrl,
            equals('https://discord.com/api/webhooks/123/abcscript'));
        expect(sanitized.discord!.channelId, equals('123456789test'));
        expect(
            sanitized.discord!.mentionUsers!.keys.first, equals('userscript'));
      });
    });
  });
}
