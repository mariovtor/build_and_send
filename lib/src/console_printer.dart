library build_and_send;

import 'dart:async';
import 'dart:io';

import 'package:ansi/ansi.dart' as ansi;

class ConsolePrinter {
  final Duration defaultUpdateInterval;
  final List<String> progressers;
  ConsolePrinter({
    required this.defaultUpdateInterval,
    required this.progressers,
  });

  factory ConsolePrinter.slashes() {
    return ConsolePrinter(
      defaultUpdateInterval: Duration(milliseconds: 80),
      progressers: ['\\', '|', '/', '-'],
    );
  }

  Future<void> writeProgress(
    String message, {
    required Future Function() run,
    Duration? updateInterval,
    List<String>? progressers,
  }) async {
    return writeProgressMessage(
      message,
      run: run,
      updateInterval: updateInterval ?? defaultUpdateInterval,
      progressers: progressers ?? this.progressers,
    );
  }

  static void writeError(String message, {bool shouldExit = true}) {
    stdout.writeln(ansi.red(message));
    if (shouldExit) {
      exit(0);
    }
  }

  static void writeGreen(String message) {
    stdout.writeln(ansi.green(message));
  }

  static void writeWhite(String message) {
    stdout.writeln(ansi.white(message));
  }

  static Future<void> writeProgressMessage(
    String message, {
    required Future Function() run,
    Duration? updateInterval,
    List<String>? progressers,
  }) async {
    updateInterval ??= Duration(milliseconds: 1000);
    progressers ??= ['\\', '|', '/', '-'];

    final completer = Completer<void>();
    try {
      run().whenComplete(() => completer.complete());
    } catch (e) {
      completer.completeError(e);
    }
    int i = 0;
    while (!completer.isCompleted) {
      await Future.delayed(updateInterval);
      stdout.write('\r${ansi.yellow('\r$message  ${progressers[i]}')}  ');
      i = (i + 1) % progressers.length;
    }
    await Future.delayed(Duration(seconds: 1));
    stdout.write('\r${ansi.yellow('\r$message.')}    ');
    await Future.delayed(updateInterval);
    stdout.writeln();
  }
}
