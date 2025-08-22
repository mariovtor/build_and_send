library build_and_send;

import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/uploaders/gcloud_uploader.dart';
import 'package:build_and_send/src/uploaders/upload_service.dart';
import 'package:test/test.dart';

void main() {
  group('UploadService', () {
    group('create', () {
      test('should return GCloudUploader when gcloud config is provided', () {
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
          ios: IosConfig(),
          flavors: {},
          discord: null,
        );

        final uploader = UploadService.create(
          config: config,
          uploadAccount: 'test@example.com',
          verbose: true,
        );

        expect(uploader, isA<GCloudUploader>());
        expect((uploader as GCloudUploader).uploadAccount,
            equals('test@example.com'));
        expect(uploader.verbose, isTrue);
      });

      test('should return null when no gcloud config is provided', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
            gcloud: null, // No gcloud config
          ),
          ios: IosConfig(),
          flavors: {},
          discord: null,
        );

        final uploader = UploadService.create(
          config: config,
          uploadAccount: 'test@example.com',
          verbose: true,
        );

        expect(uploader, isNull);
      });

      test('should create uploader with correct verbose setting', () {
        final config = BuildConfig(
          method: 'default',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
            gcloud: GCloudConfig(
              bucket: 'test-bucket-2',
              appId: 'com.example.app2',
            ),
          ),
          ios: IosConfig(),
          flavors: {},
          discord: null,
        );

        final uploader = UploadService.create(
          config: config,
          uploadAccount: 'dev@example.com',
          verbose: false,
        );

        expect(uploader, isA<GCloudUploader>());
        expect((uploader as GCloudUploader).verbose, isFalse);
        expect(uploader.gcloudConfig.bucket, equals('test-bucket-2'));
        expect(uploader.gcloudConfig.appId, equals('com.example.app2'));
      });
    });
  });
}
