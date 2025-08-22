library build_and_send;

import 'console_printer.dart';

/// Centralized logging system for verbose output
class Logger {
  static bool _verbose = false;
  static String _currentSection = '';

  /// Initialize logger with verbose mode
  static void init({required bool verbose}) {
    _verbose = verbose;
  }

  /// Log info message (only in verbose mode)
  static void info(String message) {
    if (_verbose) {
      ConsolePrinter.writeBlue('[INFO] $message');
    }
  }

  /// Log debug message (only in verbose mode)
  static void debug(String message) {
    if (_verbose) {
      ConsolePrinter.writeWhite('[DEBUG] $message');
    }
  }

  /// Log warning message (always shown)
  static void warning(String message) {
    ConsolePrinter.writeYellow('[WARNING] $message');
  }

  /// Log error message (always shown)
  static void error(String message) {
    ConsolePrinter.writeError('[ERROR] $message', shouldExit: false);
  }

  /// Log success message (always shown)
  static void success(String message) {
    ConsolePrinter.writeGreen('[SUCCESS] $message');
  }

  /// Start a new section in logs (only in verbose mode)
  static void startSection(String sectionName) {
    if (_verbose) {
      _currentSection = sectionName;
      ConsolePrinter.writeBlue('━━━ Starting: $sectionName ━━━');
    }
  }

  /// End current section in logs (only in verbose mode)
  static void endSection([String? result]) {
    if (_verbose && _currentSection.isNotEmpty) {
      final resultText = result != null ? ' ($result)' : '';
      ConsolePrinter.writeBlue(
          '━━━ Completed: $_currentSection$resultText ━━━\n');
      _currentSection = '';
    }
  }

  /// Log command execution (only in verbose mode)
  static void command(String command) {
    if (_verbose) {
      ConsolePrinter.writeWhite('[CMD] Running: $command');
    }
  }

  /// Log command output (only in verbose mode)
  static void commandOutput(String output) {
    if (_verbose && output.trim().isNotEmpty) {
      ConsolePrinter.writeWhite('[OUT] $output');
    }
  }

  /// Log configuration values (only in verbose mode)
  static void config(String key, dynamic value) {
    if (_verbose) {
      ConsolePrinter.writeBlue('[CONFIG] $key: $value');
    }
  }

  /// Log step progress (only in verbose mode)
  static void step(String stepName) {
    if (_verbose) {
      ConsolePrinter.writeWhite('  → $stepName');
    }
  }

  /// Check if verbose mode is enabled
  static bool get isVerbose => _verbose;
}
