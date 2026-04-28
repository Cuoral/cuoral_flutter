// _cuoral_reporter.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CuoralReporter {
  static final CuoralReporter _instance = CuoralReporter._internal();
  factory CuoralReporter() => _instance;
  CuoralReporter._internal();

  String? _publicKey;
  String? _sessionId;

  final String _crashUrl = 'https://api.cuoral.com/v1/errors';
  final String _analyticsUrl = 'https://api.cuoral.com/v1/analytics';

  // A flag to ensure we only try to send queued reports once per session
  bool _isSendingQueuedReports = false;

  void init({required String publicKey}) {
    _publicKey = publicKey;
    _setupGlobalHandlers();
    _sendQueuedReports(); // this is to check for and send reports on launch
  }

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  void reportError(
    dynamic error,
    StackTrace stack, {
    Map<String, dynamic>? details,
  }) async {
    final Map<String, dynamic> report = {
      'type': 'crash', // Add this field
      'public_key': _publicKey,
      'session_id': _sessionId,
      'error_message': error.toString(),
      'stack_trace': stack.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'details': details,
    };

    _queueReport(report);
  }

  void reportNavigationEvent(Map<String, dynamic> details) {
    if (_publicKey == null) return;

    final Map<String, dynamic> event = {
      'type': 'navigation', // Add this field
      'public_key': _publicKey,
      'session_id': _sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'details': details,
    };

    _queueReport(event);
  }

  // This new method handles the queuing logic for both types of reports
  Future<void> _queueReport(Map<String, dynamic> report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/cuoral_report_${DateTime.now().microsecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonEncode(report));
    } catch (e) {}
  }

  Future<void> _sendQueuedReports() async {
    if (_isSendingQueuedReports) return;
    _isSendingQueuedReports = true;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final files =
          directory
              .listSync()
              .where((file) => file.path.contains('cuoral_report_'))
              .toList();

      for (final file in files) {
        try {
          final jsonString = await (file as File).readAsString();
          final report = jsonDecode(jsonString);

          final String url =
              report['type'] == 'crash' ? _crashUrl : _analyticsUrl;

          final response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(report),
          );

          if (response.statusCode == 200) {
            await file.delete();
          }
        } catch (e) {}
      }
    } catch (e) {
    } finally {
      _isSendingQueuedReports = false;
    }
  }

  void _setupGlobalHandlers() {
    FlutterError.onError ??= (details) {
      FlutterError.presentError(details);
      _instance.reportError(
        details.exception,
        details.stack!,
        details: {'source': 'flutter_framework'},
      );
    };

    PlatformDispatcher.instance.onError ??= (error, stack) {
      _instance.reportError(
        error,
        stack,
        details: {'source': 'platform_dispatcher'},
      );
      return true;
    };
  }
}
