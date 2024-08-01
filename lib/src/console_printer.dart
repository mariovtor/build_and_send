library build_and_send;

import 'dart:async';
import 'dart:io';

import 'package:ansi/ansi.dart' as ansi;

/// Class to print messages to the console
/// This class will print messages to the console
/// with different colors
class ConsolePrinter {
  /// Default update interval
  final Duration defaultUpdateInterval;

  /// Progressers
  /// List of progressers to use
  /// for the progress message
  /// This will be used to show a progress message
  /// with different progressers
  /// Default is ['\\', '|', '/', '-']
  /// You can provide your own list of progressers
  final List<String> progressers;
  ConsolePrinter({
    required this.defaultUpdateInterval,
    required this.progressers,
  });

  /// Create a new instance of ConsolePrinter with slashes
  factory ConsolePrinter.slashes() {
    return ConsolePrinter(
      defaultUpdateInterval: Duration(milliseconds: 80),
      progressers: ['\\', '|', '/', '-'],
    );
  }

  /// Write a progress message to the console
  /// This method will write a progress message to the console
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

  /// Write a error message to the console
  static void writeError(String message, {bool shouldExit = true}) {
    stdout.writeln(ansi.red(message));
    if (shouldExit) {
      exit(0);
    }
  }

  /// Write a green message to the console
  static void writeGreen(String message) {
    stdout.writeln(ansi.green(message));
  }

  /// Write a white message to the console
  static void writeWhite(String message) {
    stdout.writeln(ansi.white(message));
  }

  /// Write a progress message to the console
  /// This method will write a progress message to the console
  /// with different progressers
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
