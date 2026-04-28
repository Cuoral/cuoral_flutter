import 'package:flutter/services.dart';

/// Platform interface for Cuoral native functionality
///
/// Handles communication with native Android and iOS code for:
/// - Native crash tracking
/// - Screen recording
class CuoralPlatform {
  static const MethodChannel _channel = MethodChannel('cuoral_flutter');

  /// Singleton instance
  static final CuoralPlatform instance = CuoralPlatform._();

  CuoralPlatform._();

  /// Initialize native crash tracking
  ///
  /// [sessionId] - Current session ID
  /// [publicKey] - Cuoral public API key
  Future<void> initializeCrashTracking({
    required String sessionId,
    required String publicKey,
  }) async {
    try {
      await _channel.invokeMethod('initializeCrashTracking', {
        'sessionId': sessionId,
        'publicKey': publicKey,
      });
    } catch (e) {
      // Fail silently
    }
  }

  /// Check if screen recording is available
  Future<bool> isRecordingAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRecordingAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start screen recording
  ///
  /// [withAudio] - Include audio in recording (default: true)
  ///
  /// Returns true if recording started successfully
  Future<bool> startRecording({bool withAudio = true}) async {
    try {
      final result = await _channel.invokeMethod<bool>('startRecording', {
        'withAudio': withAudio,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stop screen recording
  ///
  /// Returns the file path of the recorded video
  Future<String?> stopRecording() async {
    try {
      final result = await _channel.invokeMethod<String>('stopRecording');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Recording error: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Recording error: $e');
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRecording');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get platform version (for testing)
  Future<String?> getPlatformVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getPlatformVersion');
      return version;
    } catch (e) {
      return null;
    }
  }
}
