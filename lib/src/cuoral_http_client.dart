import 'dart:async';
import 'package:http/http.dart' as http;

/// HTTP client wrapper that automatically tracks network errors
///
/// Wraps the standard HTTP client to intercept requests and track
/// 4xx and 5xx errors to Cuoral.
class CuoralHttpClient extends http.BaseClient {
  final http.Client _inner;
  final dynamic _cuoral; // Avoid circular dependency

  CuoralHttpClient(this._inner, this._cuoral);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    try {
      final response = await _inner.send(request);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // Track 4xx and 5xx errors
      if (response.statusCode >= 400) {
        // Read response body if available
        String? responseBody;
        try {
          final bodyBytes = await response.stream.toBytes();
          responseBody = String.fromCharCodes(bodyBytes);

          // Create new response with the body bytes we just read
          final newResponse = http.StreamedResponse(
            Stream.value(bodyBytes),
            response.statusCode,
            headers: response.headers,
            isRedirect: response.isRedirect,
            persistentConnection: response.persistentConnection,
            reasonPhrase: response.reasonPhrase,
            request: response.request,
          );

          // Track the error
          _cuoral.trackNetworkError(
            url: request.url.toString(),
            method: request.method,
            status: response.statusCode,
            duration: duration,
            requestBody: _getRequestBody(request),
            responseBody: responseBody,
          );

          return newResponse;
        } catch (e) {
          // If we fail to read body, just track without it
          _cuoral.trackNetworkError(
            url: request.url.toString(),
            method: request.method,
            status: response.statusCode,
            duration: duration,
            requestBody: _getRequestBody(request),
          );

          return response;
        }
      }

      return response;
    } catch (error) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // Track network failure
      _cuoral.trackNetworkError(
        url: request.url.toString(),
        method: request.method,
        status: 0,
        duration: duration,
        requestBody: _getRequestBody(request),
        error: error.toString(),
      );

      rethrow;
    }
  }

  /// Extract request body if possible
  String? _getRequestBody(http.BaseRequest request) {
    try {
      if (request is http.Request) {
        return request.body;
      }
    } catch (e) {
      // Fail silently
    }
    return null;
  }
}
