library build_and_send;

import 'dart:io';

import '../console_printer.dart';
import '../logger.dart';
import 'builder.dart';

typedef RunCommandFunction = Future<void> Function(
  String command, {
  String? startMessage,
  String? errorMessage,
  String? successMessage,
  String? progressMessage,
  Function(ProcessResult)? onRun,
});

class IOSBuilder implements Builder {
  final String buildMethod;
  final bool noPodSync;
  final bool verbose;
  final RunCommandFunction _runCommand;

  IOSBuilder({
    required this.buildMethod,
    this.noPodSync = true,
    this.verbose = false,
    RunCommandFunction? runCommand,
  }) : _runCommand = runCommand ?? _defaultRunCommand;

  @override
  Future<BuildResult> build(BuildContext context) async {
    Logger.startSection('iOS Build');
    Logger.debug('Build method: $buildMethod');
    Logger.debug('No pod sync: $noPodSync');
    Logger.debug('Verbose mode: $verbose');
    Logger.debug('Only upload: ${context.onlyUpload}');

    if (!Platform.isMacOS) {
      Logger.error('iOS builds are only supported on macOS');
      Logger.endSection();
      return BuildResult.failure('iOS builds are only supported on macOS');
    }

    try {
      if (!context.onlyUpload) {
        Logger.step('Building iOS IPA');
        await _buildIPA(context);
        Logger.success('iOS build artifacts created successfully');
      } else {
        Logger.info('Skipping build (only-upload mode)');
      }
      Logger.endSection();
      return BuildResult.success();
    } catch (e) {
      Logger.error('iOS build failed: $e');
      Logger.endSection();
      return BuildResult.failure(e.toString());
    }
  }

  Future<void> _buildIPA(BuildContext context) async {
    if (noPodSync) {
      Logger.step('Running pod sync');
      await _runPodSync();
    }

    Logger.step('Building IPA file');
    final flavorArg =
        context.flavorName != null ? '--flavor ${context.flavorName}' : '';
    final targetArg = context.flavorName != null
        ? '--target lib/main_${context.flavorName}.dart'
        : '';

    String command =
        'fvm flutter build ipa --release $flavorArg $targetArg ${context.buildArgs}';

    Logger.debug('Build method: $buildMethod');
    if (buildMethod == 'fvm') {
      command = 'fvm $command';
    } else if (buildMethod == 'shorebird') {
      command =
          'shorebird release ios --no-confirm $targetArg $flavorArg ${context.buildArgs}';
    }

    Logger.command(command);
    await _runCommand(
      command,
      startMessage: 'Started building IPA',
      progressMessage: 'Building IPA',
    );
  }

  Future<void> _runPodSync() async {
    Logger.debug('Cleaning up pods and running pod install');
    String cleanCommand = '''
      cd ios
      pod deintegrate
      rm Podfile.lock
      rm -rf .symlinks
      pod install
      cd ..
      ''';
    Logger.command(cleanCommand.trim());
    await _runCommand(cleanCommand, progressMessage: 'Running Pod Sync');
  }

  static Future<void> _defaultRunCommand(
    String command, {
    String? startMessage,
    String? errorMessage,
    String? successMessage,
    String? progressMessage,
    Function(ProcessResult)? onRun,
  }) async {
    Logger.debug('Executing command: $command');
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

        final out = <String>[];
        process.stdout.listen((event) {
          final text = stdout.encoding.decode(event);
          out.add(text);
        });

        final err = <String>[];
        process.stderr.listen((event) {
          final text = stderr.encoding.decode(event);
          err.add(text);
        });

        final exitCode = await process.exitCode;
        result = ProcessResult(
          process.pid,
          exitCode,
          out.join(),
          err.join(),
        );

        if (exitCode != 0) {
          Logger.error('Command failed with exit code $exitCode');
          if (out.isNotEmpty) {
            Logger.info('Command stdout:');
            ConsolePrinter.writeWhite(out.join().trim());
          }
          if (err.isNotEmpty) {
            // Filter out irrelevant "yes: stdout: Broken pipe" errors
            final relevantErrors = err
                .where((error) => !error.contains('yes: stdout: Broken pipe'))
                .toList();
            if (relevantErrors.isNotEmpty) {
              Logger.error('Command stderr:');
              ConsolePrinter.writeError(relevantErrors.join().trim(),
                  shouldExit: false);
            }
          }

          // Use stderr for exception message, but filter out broken pipe
          final relevantErrorText = err
              .where((error) => !error.contains('yes: stdout: Broken pipe'))
              .join()
              .trim();
          final errorMsg =
              relevantErrorText.isEmpty ? 'Command failed' : relevantErrorText;

          throw Exception('Command failed with exit code $exitCode: $errorMsg');
        } else {
          onRun?.call(result);
          ConsolePrinter.writeGreen(
              successMessage ?? 'Command completed successfully');
        }
      } catch (e) {
        Logger.error('Exception during command execution: $e');
        ConsolePrinter.writeError(
            errorMessage ?? 'Failed to run command: $command');
        if (result != null) {
          if (result.stdout.toString().isNotEmpty) {
            ConsolePrinter.writeWhite('Output: ${result.stdout}');
          }
          if (result.stderr.toString().isNotEmpty) {
            ConsolePrinter.writeError('Error output: ${result.stderr}',
                shouldExit: false);
          }
        }
        rethrow;
      } finally {
        process?.kill();
      }
    }

    if (progressMessage != null) {
      await ConsolePrinter.slashes().writeProgress(progressMessage,
          run: () async {
        await runCommand();
      });
    } else {
      await runCommand();
    }
  }
}
