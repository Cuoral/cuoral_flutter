import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'intelligence.dart';
import 'cuoral_http_overrides.dart';
import 'cuoral_platform.dart';

/// Main Cuoral SDK class for Flutter applications
///
/// Provides customer intelligence tracking and screen recording capabilities.
/// Usage:
/// ```dart
/// await Cuoral.instance.initialize(
///   publicKey: 'your-public-key',
///   email: 'user@example.com',
///   firstName: 'John',
///   lastName: 'Doe',
/// );
/// ```
class Cuoral {
  static final Cuoral _instance = Cuoral._internal();
  static Cuoral get instance => _instance;

  Cuoral._internal();

  // Configuration
  String? _publicKey;
  String? _sessionId;
  String? _email;
  String? _firstName;
  String? _lastName;

  // Feature flags from backend
  bool _customerIntelligenceEnabled = false;

  // Components
  Intelligence? _intelligence;

  // State
  bool _isInitialized = false;

  // Constants
  static const String _baseUrl = 'https://api.cuoral.com';
  static const String _storageKey = '__x_loadID';

  /// Check if the SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Get the Intelligence tracking instance
  Intelligence? get intelligence => _intelligence;

  /// Initialize the Cuoral SDK
  ///
  /// [publicKey] - Your Cuoral public API key (required)
  /// [email] - User's email address (optional)
  /// [firstName] - User's first name (optional)
  /// [lastName] - User's last name (optional)
  ///
  /// Returns true if initialization was successful
  Future<bool> initialize({
    required String publicKey,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      _publicKey = publicKey;
      _email = email;
      _firstName = firstName;
      _lastName = lastName;

      // Load or create session
      await _loadOrCreateSession();

      // If no session exists, create a new one
      Map<String, dynamic>? sessionData;
      if (_sessionId == null) {
        sessionData = await _initiateSession();

        // If server is down and we couldn't create session, work without one
        if (sessionData == null) {
          // Don't return false - continue initialization
        }
      } else {
        // Validate existing session with backend
        sessionData = await _getSessionConfiguration(_sessionId!);

        // If validation fails with 404/400, try to create new session
        // But if it's 502/504, sessionData will have the existing sessionId, so we continue
        if (sessionData == null) {
          final oldSessionId = _sessionId;
          _sessionId = null;
          sessionData = await _initiateSession();

          // If server is down, keep using the old session ID
          if (sessionData == null && oldSessionId != null) {
            sessionData = {
              'sessionId': oldSessionId,
              'customer_intelligence': true,
              'session_data': {},
            };
          }
        }
      }

      if (sessionData != null) {
        _sessionId = sessionData['sessionId'];
        _customerIntelligenceEnabled =
            sessionData['customer_intelligence'] ?? false;

        // Set profile if we have user info and session doesn't have it yet
        final sessionEmail = sessionData['email'] as String?;

        if (_email != null &&
            _email!.isNotEmpty &&
            _firstName != null &&
            _firstName!.isNotEmpty &&
            _lastName != null &&
            _lastName!.isNotEmpty &&
            (sessionEmail == null || sessionEmail.isEmpty)) {
          await _setProfile(
            sessionId: _sessionId!,
            email: _email!,
            name: '$_firstName $_lastName',
          );
        }

        // Initialize intelligence tracking if enabled
        if (_customerIntelligenceEnabled && _sessionId != null) {
          _intelligence = Intelligence(
            publicKey: _publicKey!,
            sessionId: _sessionId!,
          );
          await _intelligence!.initialize();

          // Install automatic HTTP interceptor to track ALL network requests
          // This mimics the behavior of the web/Ionic implementation
          HttpOverrides.global = CuoralHttpOverrides(
            onNetworkError: (url, method, status, duration, error) {
              // Track network errors automatically (4xx, 5xx)
              if (status >= 400 || error != null) {
                trackNetworkError(
                  url: url,
                  method: method,
                  status: status,
                  duration: duration,
                  error: error,
                );
              }
            },
          );
        }

        // Initialize native crash tracking
        try {
          await CuoralPlatform.instance.initializeCrashTracking(
            publicKey: _publicKey!,
            sessionId: _sessionId ?? '',
          );

        } catch (e) {
          // Fail silently
        }

        _isInitialized = true;
        return true;
      }

      // If we get here, server is down and we have no session
      // Still mark as initialized so the app can continue
      _isInitialized = true;
      return true;
    } catch (e) {
      // Fail silently - never crash the app
      return false;
    }
  }

  /// Track a page/screen view
  Future<void> trackPageView(String screenName, {String? referrer}) async {
    try {
      if (_intelligence != null && _customerIntelligenceEnabled) {
        await _intelligence!.trackPageView(screenName, referrer: referrer);
      }
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
  }) async {
    try {
      if (_intelligence != null && _customerIntelligenceEnabled) {
        await _intelligence!.trackConsoleError(
          message: message,
          stackTrace: stackTrace,
          url: url,
          line: line,
          column: column,
          logLevel: logLevel,
        );
      }
    } catch (e) {
      // Fail silently
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
      if (_intelligence != null && _customerIntelligenceEnabled) {
        await _intelligence!.trackNetworkError(
          url: url,
          method: method,
          status: status,
          duration: duration,
          requestBody: requestBody,
          responseBody: responseBody,
          error: error,
        );
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Track a custom event
  ///
  /// This allows you to track specific user actions and behaviors in your app.
  ///
  /// [name] - The event name (e.g., 'button_clicked', 'signup_completed')
  /// [category] - The event category (e.g., 'user_action', 'conversion', 'engagement')
  /// [properties] - Additional properties/metadata for the event
  /// [elementSelector] - Optional identifier for the UI element (e.g., 'signup_button')
  /// [elementText] - Optional text content of the element
  ///
  /// Example:
  /// ```dart
  /// await Cuoral.instance.trackCustomEvent(
  ///   name: 'add_to_cart',
  ///   category: 'conversion',
  ///   properties: {
  ///     'product_id': '12345',
  ///     'product_name': 'Blue Widget',
  ///     'price': 29.99,
  ///   },
  /// );
  /// ```
  Future<void> trackCustomEvent({
    required String name,
    required String category,
    Map<String, dynamic>? properties,
    String? elementSelector,
    String? elementText,
  }) async {
    try {
      if (_intelligence != null && _customerIntelligenceEnabled) {
        await _intelligence!.trackCustomEvent(
          name: name,
          category: category,
          properties: properties ?? {},
          elementSelector: elementSelector,
          elementText: elementText,
        );
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Manually flush all pending events
  ///
  /// Useful for testing or ensuring events are sent immediately before app termination.
  /// Events are normally sent automatically based on batching rules.
  Future<void> flush() async {
    try {
      if (_intelligence != null && _customerIntelligenceEnabled) {
        await _intelligence!.flush();
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Load existing session from storage or create a new one
  Future<void> _loadOrCreateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_storageKey);

      if (sessionData != null) {
        final data = jsonDecode(sessionData);
        _sessionId = data['sessionId'];

        // Validate session is not too old (optional: add expiry check)
        final createdAt = data['createdAt'] as int?;
        if (createdAt != null) {
          final age = DateTime.now().millisecondsSinceEpoch - createdAt;
          // If session is older than 30 days, create new one
          if (age > 30 * 24 * 60 * 60 * 1000) {
            _sessionId = null;
          }
        }
      }

    } catch (e) {
      // Storage failure - continue without persisted session
    }
  }

  /// Initiate or validate session with backend
  Future<Map<String, dynamic>?> _initiateSession() async {
    try {
      final url = Uri.parse('$_baseUrl/conversation/initiate-session');
      final body = {
        'public_key': _publicKey,
        'email': _email,
        'first_name': _firstName,
        'last_name': _lastName,
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-org-id': _publicKey!,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      // If server is down (502, 504), return null and SDK will work without session
      if (response.statusCode == 502 || response.statusCode == 504) {
        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSessionId = data['session_id'] as String?;
        final status = data['status'] as bool?;

        if (status == true && newSessionId != null) {
          // Save the new session
          await _saveSessionToStorage(newSessionId);

          // Fetch session configuration
          return await _getSessionConfiguration(newSessionId);
        }
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get session configuration from backend
  Future<Map<String, dynamic>?> _getSessionConfiguration(
    String sessionId,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/conversation/session/get');
      final body = {'session_id': sessionId};

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-org-id': _publicKey!,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      // If server is down (502, 504), keep existing session and continue
      if (response.statusCode == 502 || response.statusCode == 504) {
        // Return minimal config to continue with existing session
        return {
          'sessionId': sessionId,
          'customer_intelligence': true,
          'session_data': {},
        };
      }

      // If session not found or invalid request, clear it
      if (response.statusCode == 404 || response.statusCode == 400) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isExpired = data['is_expired'] as bool?;

        // If session is expired, clear it
        if (isExpired == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_storageKey);
          return null;
        }

        final config = data['configuration'] as Map<String, dynamic>?;

        return {
          'sessionId': data['session_id'] ?? sessionId,
          'customer_intelligence': config?['customer_intelligence'] ?? false,
          'session_data': config ?? {},
          'email': data['email'], // Include email from root level
          'name': data['name'], // Include name from root level
        };
      }

      // If fetch fails for other reasons, use existing session with default config
      return {
        'sessionId': sessionId,
        'customer_intelligence': true,
        'session_data': {},
      };
    } on TimeoutException {
      // Keep using the existing session
      return {
        'sessionId': sessionId,
        'customer_intelligence': true,
        'session_data': {},
      };
    } catch (e) {
      // Keep using the existing session
      return {
        'sessionId': sessionId,
        'customer_intelligence': true,
        'session_data': {},
      };
    }
  }

  /// Save session to local storage
  Future<void> _saveSessionToStorage(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'sessionId': sessionId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_storageKey, jsonEncode(sessionData));

    } catch (e) {
      // Storage failure is not critical
    }
  }

  /// Set user profile for the session
  Future<void> _setProfile({
    required String sessionId,
    required String email,
    required String name,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/conversation/set-profile');
      final body = {'session_id': sessionId, 'email': email, 'name': name};

      await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-org-id': _publicKey!,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Fail silently
    }
  }

  /// Dispose and cleanup resources
  void dispose() {
    _intelligence?.dispose();
    _isInitialized = false;
  }
}
