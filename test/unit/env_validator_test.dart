library build_and_send;

import 'package:build_and_send/src/validation/env_validator.dart';
import 'package:build_and_send/src/validation/input_validator.dart';
import 'package:test/test.dart';

void main() {
  group('EnvValidator', () {
    group('validateGCloudEnv', () {
      test('should accept valid GCloud environment variables', () {
        final env = {
          'GCLOUD_SERVICE_ACCOUNT': 'path/to/service-account.json',
          'GCLOUD_PROJECT_ID': 'my-project-id',
        };

        expect(() => EnvValidator.validateGCloudEnv(env), returnsNormally);
      });

      test('should reject GCloud project ID with spaces', () {
        final env = {
          'GCLOUD_PROJECT_ID': 'invalid project id',
        };

        expect(() => EnvValidator.validateGCloudEnv(env),
            throwsA(isA<ValidationException>()));
      });

      test('should validate service account file path', () {
        final env = {
          'GCLOUD_SERVICE_ACCOUNT': '../../../etc/passwd',
        };

        expect(() => EnvValidator.validateGCloudEnv(env),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateIOSEnv', () {
      test('should accept valid iOS environment variables', () {
        final env = {
          'IOS_UPLOAD_EMAIL': 'test@example.com',
          'IOS_UPLOAD_PASSWORD': 'secure-password',
        };

        expect(() => EnvValidator.validateIOSEnv(env), returnsNormally);
      });

      test('should accept legacy account environment variables', () {
        final env = {
          'ACCOUNT_EMAIL': 'test@example.com',
          'ACCOUNT_PASSWORD': 'secure-password',
        };

        expect(() => EnvValidator.validateIOSEnv(env), returnsNormally);
      });

      test('should reject invalid email format', () {
        final env = {
          'IOS_UPLOAD_EMAIL': 'invalid-email',
          'IOS_UPLOAD_PASSWORD': 'password',
        };

        expect(() => EnvValidator.validateIOSEnv(env),
            throwsA(isA<ValidationException>()));
      });

      test('should require password when email is provided', () {
        final env = {
          'IOS_UPLOAD_EMAIL': 'test@example.com',
        };

        expect(() => EnvValidator.validateIOSEnv(env),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateDiscordEnv', () {
      test('should accept valid Discord webhook URL', () {
        final env = {
          'DISCORD_WEBHOOK_URL':
              'https://discord.com/api/webhooks/123456789/abcdef',
        };

        expect(() => EnvValidator.validateDiscordEnv(env), returnsNormally);
      });

      test('should reject invalid webhook URL', () {
        final env = {
          'DISCORD_WEBHOOK_URL': 'not-a-url',
        };

        expect(() => EnvValidator.validateDiscordEnv(env),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateAll', () {
      test('should validate all environment variables together', () {
        final env = {
          'GCLOUD_PROJECT_ID': 'valid-project',
          'IOS_UPLOAD_EMAIL': 'test@example.com',
          'IOS_UPLOAD_PASSWORD': 'password',
          'DISCORD_WEBHOOK_URL': 'https://discord.com/api/webhooks/123/abc',
        };

        expect(() => EnvValidator.validateAll(env), returnsNormally);
      });

      test('should catch any validation error in combined validation', () {
        final env = {
          'GCLOUD_PROJECT_ID': 'invalid project id',
          'IOS_UPLOAD_EMAIL': 'invalid-email',
          'DISCORD_WEBHOOK_URL': 'not-a-url',
        };

        expect(() => EnvValidator.validateAll(env),
            throwsA(isA<ValidationException>()));
      });
    });

    group('sanitizeEnvVars', () {
      test('should sanitize all environment variable keys and values', () {
        final env = {
          'TEST_KEY<script>': 'value<script>',
          'ANOTHER_KEY"quote': 'another"value',
          '  SPACED_KEY  ': '  spaced_value  ',
        };

        final sanitized = EnvValidator.sanitizeEnvVars(env);

        expect(sanitized['TEST_KEYscript'], equals('valuescript'));
        expect(sanitized['ANOTHER_KEYquote'], equals('anothervalue'));
        expect(sanitized['SPACED_KEY'], equals('spaced_value'));
      });
    });
  });
}
