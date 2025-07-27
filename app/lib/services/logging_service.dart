import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Clean logging service - beautiful dev logs, Firebase error reporting in production
class LoggingService {
  static final Map<String, Logger> _loggers = {};

  static Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      _loggers[name] = Logger(
        level: kDebugMode ? Level.debug : Level.off,
        printer: kDebugMode 
          ? SimplePrinter(colors: true)
          : null,
        output: kDebugMode ? ConsoleOutput() : _FirebaseLogOutput(),
      );
    }
    return _loggers[name]!;
  }

  /// Report error to Firebase Crashlytics
  static void reportError(String message, dynamic error, StackTrace? stackTrace) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  /// Report fatal error to Firebase Crashlytics
  static void reportFatalError(String message, dynamic error, StackTrace? stackTrace) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }
}

/// Custom output that sends errors to Firebase in production
class _FirebaseLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Only send errors and warnings to Firebase
    if (event.level.index >= Level.warning.index) {
      FirebaseCrashlytics.instance.log(event.lines.join('\n'));
      
      // For errors, also record as error
      if (event.level.index >= Level.error.index) {
        FirebaseCrashlytics.instance.recordError(
          event.lines.join('\n'),
          null,
          reason: 'App Error',
          fatal: false,
        );
      }
    }
  }
}