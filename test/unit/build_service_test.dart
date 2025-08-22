library build_and_send;

import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/builders/android_builder.dart';
import 'package:build_and_send/src/builders/build_service.dart';
import 'package:build_and_send/src/builders/ios_builder.dart';
import 'package:test/test.dart';

void main() {
  group('BuildService', () {
    late FlavorConfig mockFlavorConfig;

    setUp(() {
      mockFlavorConfig = FlavorConfig(
        method: 'default',
        android: AndroidConfig(
          apkPath: 'build/app/outputs/flutter-apk/',
          bundlePath: 'build/app/outputs/bundle/release',
          apkName: 'app-release.apk',
          bundleName: 'app-release.aab',
        ),
        ios: IosConfig(),
      );
    });

    group('createAndroidBuilder', () {
      test('should return AndroidBuilder with correct configuration', () {
        final builder = BuildService.createAndroidBuilder(
          flavor: mockFlavorConfig,
          verbose: true,
        );

        expect(builder, isA<AndroidBuilder>());
        expect((builder as AndroidBuilder).buildMethod, equals('default'));
        expect(builder.verbose, isTrue);
      });

      test('should return AndroidBuilder with verbose false', () {
        final builder = BuildService.createAndroidBuilder(
          flavor: mockFlavorConfig,
          verbose: false,
        );

        expect(builder, isA<AndroidBuilder>());
        expect((builder as AndroidBuilder).verbose, isFalse);
      });
    });

    group('createIOSBuilder', () {
      test('should return IOSBuilder with correct configuration', () {
        final builder = BuildService.createIOSBuilder(
          flavor: mockFlavorConfig,
          verbose: true,
          noPodSync: true,
        );

        expect(builder, isA<IOSBuilder>());
        expect((builder as IOSBuilder).buildMethod, equals('default'));
        expect(builder.verbose, isTrue);
      });

      test('should return IOSBuilder with verbose false', () {
        final builder = BuildService.createIOSBuilder(
          flavor: mockFlavorConfig,
          verbose: false,
          noPodSync: false,
        );

        expect(builder, isA<IOSBuilder>());
        expect((builder as IOSBuilder).verbose, isFalse);
      });
    });

    group('factory methods with different build methods', () {
      test('should create builder with fvm method', () {
        final fvmFlavorConfig = FlavorConfig(
          method: 'fvm',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
          ),
          ios: IosConfig(),
        );

        final androidBuilder = BuildService.createAndroidBuilder(
          flavor: fvmFlavorConfig,
          verbose: false,
        );
        final iosBuilder = BuildService.createIOSBuilder(
          flavor: fvmFlavorConfig,
          verbose: false,
          noPodSync: true,
        );

        expect((androidBuilder as AndroidBuilder).buildMethod, equals('fvm'));
        expect((iosBuilder as IOSBuilder).buildMethod, equals('fvm'));
      });

      test('should create builder with shorebird method', () {
        final shorebirdFlavorConfig = FlavorConfig(
          method: 'shorebird',
          android: AndroidConfig(
            apkPath: 'build/app/outputs/flutter-apk/',
            bundlePath: 'build/app/outputs/bundle/release',
            apkName: 'app-release.apk',
            bundleName: 'app-release.aab',
          ),
          ios: IosConfig(),
        );

        final androidBuilder = BuildService.createAndroidBuilder(
          flavor: shorebirdFlavorConfig,
          verbose: true,
        );
        final iosBuilder = BuildService.createIOSBuilder(
          flavor: shorebirdFlavorConfig,
          verbose: true,
          noPodSync: true,
        );

        expect((androidBuilder as AndroidBuilder).buildMethod,
            equals('shorebird'));
        expect((iosBuilder as IOSBuilder).buildMethod, equals('shorebird'));
      });
    });
  });
}
