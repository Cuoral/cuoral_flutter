import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'event_queue.dart';

/// Intelligence tracking system for Cuoral
///
/// Tracks page views, console errors, and network errors with automatic batching.
class Intelligence {
  final String publicKey;
  final String sessionId;

  // Event queues for different event types
  late final EventQueue _pageViewQueue;
  late final EventQueue _consoleErrorQueue;
  late final EventQueue _networkErrorQueue;

  // Custom events - special handling (not an EventQueue)
  final List<Map<String, dynamic>> _customEventsList = [];
  Timer? _customEventsTimer;
  bool _isFlushingCustomEvents = false;

  // Current screen tracking
  String? _currentScreen;
  String? _previousScreen;

  // Device metadata
  Map<String, dynamic>? _deviceMetadata;

  // Constants
  static const String _baseUrl = 'https://api.cuoral.com';

  Intelligence({required this.publicKey, required this.sessionId});

  /// Initialize the intelligence tracking system
  Future<void> initialize() async {
    try {
      // Initialize event queues
      _pageViewQueue = EventQueue(
        endpoint: '$_baseUrl/customer-intelligence/page-view',
        publicKey: publicKey,
      );

      _consoleErrorQueue = EventQueue(
        endpoint: '$_baseUrl/customer-intelligence/console-error',
        publicKey: publicKey,
      );

      _networkErrorQueue = EventQueue(
        endpoint: '$_baseUrl/customer-intelligence/api-response',
        publicKey: publicKey,
      );

      // Collect device metadata
      await _collectDeviceMetadata();

      // Setup error handlers
      _setupErrorHandlers();
    } catch (e) {
      // Fail silently
    }
  }

  /// Track a page/screen view
  Future<void> trackPageView(String screenName, {String? referrer}) async {
    try {
      _previousScreen = _currentScreen;
      _currentScreen = screenName;

      final event = {
        'url': screenName,
        'title': screenName,
        'referrer': referrer ?? _previousScreen ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'session_id': sessionId,
        'source': 'mobile',
        'metadata': _deviceMetadata ?? {},
      };

      _pageViewQueue.addEvent(event);
    } catch (e) {
      // Fail silently
    }
  }

  /// Track a console error
  Future<void> trackConsoleError({
    required String message,
    String? stackTrace,
    String? url,
    int? line,
    int? column,
    String logLevel = 'error',
    String? errorType,
  }) async {
    try {
      final event = {
        'message': message,
        'stack_trace': stackTrace ?? '',
        'log_level': logLevel,
        'url': url ?? _currentScreen ?? 'unknown',
        'line': line ?? 0,
        'column': column ?? 0,
        'session_id': sessionId,
        'source': 'mobile',
        'console_metadata': {
          ...?_deviceMetadata,
          'error_type': errorType ?? 'javascript_error',
        },
      };

      _consoleErrorQueue.addEvent(event);
    } catch (e) {
      // Fail silently - don't log to avoid recursion
    }
  }

  /// Track a network error (4xx or 5xx response)
  Future<void> trackNetworkError({
    required String url,
    required String method,
    required int status,
    required int duration,
    String? requestBody,
    String? responseBody,
    String? error,
  }) async {
    try {
      final event = {
        'url': url,
        'method': method,
        'status_code': status, // Backend expects 'status_code', not 'status'
        'duration': duration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'session_id': sessionId,
        'source': 'mobile',
        'request_body': requestBody ?? {},
        'response_body':
            responseBody != null ? {'body': responseBody} : {}, // Must be dict
        'error': status >= 400,
        'api_metadata': {...?_deviceMetadata, 'error_message': error},
      };

      if (error != null) {
        event['error_message'] = error;
      }

      _networkErrorQueue.addEvent(event);
    } catch (e) {
      // Fail silently
    }
  }

  /// Collect device metadata
  Future<void> _collectDeviceMetadata() async {
    try {
      _deviceMetadata = {
        'device_model': 'Unknown',
        'os_version': Platform.operatingSystemVersion,
        'platform': Platform.operatingSystem,
        'app_version': '1.0.0', // Should be passed from app
      };

      // Add platform-specific metadata
      if (Platform.isAndroid) {
        _deviceMetadata!['device_model'] = 'Android Device';
      } else if (Platform.isIOS) {
        _deviceMetadata!['device_model'] = 'iOS Device';
      }
    } catch (e) {
      // Fail silently
      _deviceMetadata = {};
    }
  }

  /// Setup error handlers to catch unhandled errors
  void _setupErrorHandlers() {
    // This is handled at the app level, not here
    // See Cuoral.runZonedGuarded() for implementation
  }

  /// Track a custom event
  Future<void> trackCustomEvent({
    required String name,
    required String category,
    Map<String, dynamic>? properties,
    String? elementSelector,
    String? elementText,
  }) async {
    try {
      final eventObject = {
        'session_id': sessionId, // Required in each event object
        'name': name,
        'category': category,
        'url': _currentScreen ?? 'unknown',
        'element_selector': elementSelector,
        'element_text': elementText,
        'event_timestamp': DateTime.now().toIso8601String(),
        'properties': {...?_deviceMetadata, ...?properties},
      };

      _customEventsList.add(eventObject);

      // If we have 10 events, flush immediately
      if (_customEventsList.length >= 10) {
        await _flushCustomEvents();
      } else {
        // Otherwise, reset the timer
        _resetCustomEventsTimer();
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Reset the custom events flush timer
  void _resetCustomEventsTimer() {
    _customEventsTimer?.cancel();
    _customEventsTimer = Timer(const Duration(seconds: 2), () {
      _flushCustomEvents();
    });
  }

  /// Flush custom events to backend
  Future<void> _flushCustomEvents() async {
    if (_customEventsList.isEmpty || _isFlushingCustomEvents) {
      return;
    }

    _isFlushingCustomEvents = true;
    _customEventsTimer?.cancel();

    try {
      final eventsToSend = List<Map<String, dynamic>>.from(_customEventsList);
      _customEventsList.clear();

      if (eventsToSend.isNotEmpty) {
        final payload = {
          'session_id': sessionId,
          'custom_events': eventsToSend,
        };

        final url = '$_baseUrl/customer-intelligence/session-recording/batch';

        await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'x-org-id': publicKey,
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      // Fail silently
    } finally {
      _isFlushingCustomEvents = false;
    }
  }

  /// Flush all pending events
  Future<void> flush() async {
    try {
      await Future.wait([
        _pageViewQueue.flush(),
        _consoleErrorQueue.flush(),
        _networkErrorQueue.flush(),
        _flushCustomEvents(),
      ]);
    } catch (e) {
      // Fail silently
    }
  }

  /// Get current screen name
  String? get currentScreen => _currentScreen;

  /// Dispose and cleanup
  void dispose() {
    _pageViewQueue.dispose();
    _consoleErrorQueue.dispose();
    _networkErrorQueue.dispose();
    _customEventsTimer?.cancel();
    _customEventsList.clear();
  }
}
