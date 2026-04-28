import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'cuoral.dart';

/// Run the app with Cuoral error tracking enabled
///
/// This wraps your app in error handlers to catch and track all errors.
///
/// Usage:
/// ```dart
/// void main() {
///   CuoralErrorHandler.runApp(() {
///     runApp(MyApp());
///   });
/// }
/// ```
class CuoralErrorHandler {
  /// Run app with error tracking
  static void runApp(void Function() appRunner) {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Show error in debug mode
      FlutterError.presentError(details);

      // Track error to Cuoral
      _trackFlutterError(details);
    };

    // Catch async errors and other errors outside Flutter
    runZonedGuarded(appRunner, (error, stackTrace) {
      // Track error to Cuoral
      _trackZoneError(error, stackTrace);
    });
  }

  /// Track a Flutter framework error
  static void _trackFlutterError(FlutterErrorDetails details) {
    try {
      Cuoral.instance.trackConsoleError(
        message: details.exceptionAsString(),
        stackTrace: details.stack?.toString(),
        url: 'flutter_framework',
        logLevel: 'error',
      );
    } catch (e) {
      // Fail silently - don't log to avoid recursion
    }
  }

  /// Track a zone error (async error)
  static void _trackZoneError(dynamic error, StackTrace stackTrace) {
    try {
      Cuoral.instance.trackConsoleError(
        message: error.toString(),
        stackTrace: stackTrace.toString(),
        url: 'async_error',
        logLevel: 'error',
      );
    } catch (e) {
      // Fail silently - don't log to avoid recursion
    }
  }

  /// Manually track an error
  static Future<void> trackError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) async {
    try {
      await Cuoral.instance.trackConsoleError(
        message: error.toString(),
        stackTrace: stackTrace?.toString(),
        url: context ?? 'manual',
        logLevel: 'error',
      );
    } catch (e) {
      // Fail silently
    }
  }
}
