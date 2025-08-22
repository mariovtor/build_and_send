library build_and_send;

import 'package:build_and_send/src/validation/input_validator.dart';
import 'package:test/test.dart';

void main() {
  group('InputValidator', () {
    group('validatePlatform', () {
      test('should accept valid platforms', () {
        expect(
            () => InputValidator.validatePlatform('android'), returnsNormally);
        expect(() => InputValidator.validatePlatform('ios'), returnsNormally);
        expect(() => InputValidator.validatePlatform('all'), returnsNormally);
        expect(() => InputValidator.validatePlatform(null), returnsNormally);
      });

      test('should reject invalid platforms', () {
        expect(() => InputValidator.validatePlatform('windows'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validatePlatform('linux'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validatePlatform(''),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateFlavorName', () {
      test('should accept valid flavor names', () {
        expect(() => InputValidator.validateFlavorName('dev'), returnsNormally);
        expect(() => InputValidator.validateFlavorName('staging'),
            returnsNormally);
        expect(() => InputValidator.validateFlavorName('prod_release'),
            returnsNormally);
        expect(() => InputValidator.validateFlavorName('_internal'),
            returnsNormally);
        expect(() => InputValidator.validateFlavorName(null), returnsNormally);
        expect(() => InputValidator.validateFlavorName(''), returnsNormally);
      });

      test('should reject invalid flavor names', () {
        expect(() => InputValidator.validateFlavorName('123invalid'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateFlavorName('has-dash'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateFlavorName('has space'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateFlavorName('has@symbol'),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateMentionNames', () {
      test('should accept valid mention names', () {
        expect(() => InputValidator.validateMentionNames(['user1', 'user2']),
            returnsNormally);
        expect(() => InputValidator.validateMentionNames(['validUser']),
            returnsNormally);
        expect(
            () => InputValidator.validateMentionNames(null), returnsNormally);
        expect(() => InputValidator.validateMentionNames([]), returnsNormally);
      });

      test('should reject dangerous mention names', () {
        expect(() => InputValidator.validateMentionNames(['user<script>']),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateMentionNames(['"dangerous"']),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateMentionNames(['']),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateMentionNames(['   ']),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateCustomText', () {
      test('should accept safe custom text', () {
        expect(() => InputValidator.validateCustomText('Hello world!'),
            returnsNormally);
        expect(() => InputValidator.validateCustomText('Release v1.2.3'),
            returnsNormally);
        expect(() => InputValidator.validateCustomText(null), returnsNormally);
        expect(() => InputValidator.validateCustomText(''), returnsNormally);
      });

      test('should reject potentially dangerous text', () {
        expect(() => InputValidator.validateCustomText('\$(malicious)'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateCustomText('test`whoami`'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateCustomText('test | rm -rf /'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateCustomText('test; rm file'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateCustomText('test && malicious'),
            throwsA(isA<ValidationException>()));
      });

      test('should reject overly long text', () {
        final longText = 'a' * 1001;
        expect(() => InputValidator.validateCustomText(longText),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateFilePath', () {
      test('should accept safe file paths', () {
        expect(
            () => InputValidator.validateFilePath(
                'build/app/outputs', 'test path'),
            returnsNormally);
        expect(
            () => InputValidator.validateFilePath('relative/path', 'test path'),
            returnsNormally);
        expect(() => InputValidator.validateFilePath(null, 'test path'),
            returnsNormally);
        expect(() => InputValidator.validateFilePath('', 'test path'),
            returnsNormally);
      });

      test('should reject directory traversal attempts', () {
        expect(
            () => InputValidator.validateFilePath(
                '../../../etc/passwd', 'test path'),
            throwsA(isA<ValidationException>()));
        expect(
            () => InputValidator.validateFilePath(
                'valid/../malicious', 'test path'),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateEmail', () {
      test('should accept valid email addresses', () {
        expect(() => InputValidator.validateEmail('test@example.com', 'email'),
            returnsNormally);
        expect(
            () => InputValidator.validateEmail(
                'user.name+tag@domain.co.uk', 'email'),
            returnsNormally);
        expect(
            () => InputValidator.validateEmail(null, 'email'), returnsNormally);
        expect(
            () => InputValidator.validateEmail('', 'email'), returnsNormally);
      });

      test('should reject invalid email addresses', () {
        expect(() => InputValidator.validateEmail('invalid-email', 'email'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateEmail('test@', 'email'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateEmail('@domain.com', 'email'),
            throwsA(isA<ValidationException>()));
      });
    });

    group('validateUrl', () {
      test('should accept valid URLs', () {
        expect(() => InputValidator.validateUrl('https://example.com', 'URL'),
            returnsNormally);
        expect(
            () => InputValidator.validateUrl(
                'http://localhost:8080/webhook', 'URL'),
            returnsNormally);
        expect(() => InputValidator.validateUrl(null, 'URL'), returnsNormally);
        expect(() => InputValidator.validateUrl('', 'URL'), returnsNormally);
      });

      test('should reject invalid URLs', () {
        expect(() => InputValidator.validateUrl('not-a-url', 'URL'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateUrl('ftp://example.com', 'URL'),
            throwsA(isA<ValidationException>()));
        expect(() => InputValidator.validateUrl('javascript:alert(1)', 'URL'),
            throwsA(isA<ValidationException>()));
      });
    });

    group('sanitizeString', () {
      test('should remove dangerous characters', () {
        expect(InputValidator.sanitizeString('test<script>'),
            equals('testscript'));
        expect(
            InputValidator.sanitizeString('test"quote'), equals('testquote'));
        expect(InputValidator.sanitizeString('test\$var'), equals('testvar'));
        expect(InputValidator.sanitizeString('test`cmd`'), equals('testcmd'));
        expect(InputValidator.sanitizeString('  test  '), equals('test'));
      });
    });

    group('sanitizeCommandArg', () {
      test('should remove dangerous characters from command args', () {
        expect(InputValidator.sanitizeCommandArg('test;malicious'),
            equals('testmalicious'));
        expect(
            InputValidator.sanitizeCommandArg('test|pipe'), equals('testpipe'));
        expect(InputValidator.sanitizeCommandArg('test(func)'),
            equals('testfunc'));
        expect(InputValidator.sanitizeCommandArg('test{block}'),
            equals('testblock'));
        expect(InputValidator.sanitizeCommandArg('  test  '), equals('test'));
      });
    });
  });
}
