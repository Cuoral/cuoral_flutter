import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Event batching system for Cuoral
///
/// Batches events to reduce network requests:
/// - Max batch size: 10 events
/// - Batch interval: 2 seconds
/// - Max queue size: 30 events
class EventQueue {
  final String endpoint;
  final String publicKey;
  final int maxBatchSize;
  final Duration batchInterval;
  final int maxQueueSize;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _isFlushing = false;

  EventQueue({
    required this.endpoint,
    required this.publicKey,
    this.maxBatchSize = 10,
    this.batchInterval = const Duration(seconds: 2),
    this.maxQueueSize = 30,
  });

  /// Add an event to the queue
  void addEvent(Map<String, dynamic> event) {
    try {
      // If queue is full, remove oldest event
      if (_queue.length >= maxQueueSize) {
        _queue.removeAt(0);
      }

      _queue.add(event);

      // If batch size reached, flush immediately
      if (_queue.length >= maxBatchSize) {
        flush();
      } else {
        // Otherwise, reset the timer
        _resetTimer();
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Flush all queued events to the backend
  Future<void> flush() async {
    if (_queue.isEmpty || _isFlushing) {
      return;
    }

    _isFlushing = true;
    _timer?.cancel();

    try {
      // Take up to maxBatchSize events from the queue
      final batch = _queue.take(maxBatchSize).toList();
      _queue.removeRange(0, batch.length);

      if (batch.isNotEmpty) {
        await _sendBatch(batch);
      }

      // If there are more events, reset timer for next batch
      if (_queue.isNotEmpty) {
        _resetTimer();
      }
    } catch (e) {
      // Fail silently
    } finally {
      _isFlushing = false;
    }
  }

  /// Send a batch of events to the backend
  Future<void> _sendBatch(List<Map<String, dynamic>> batch) async {
    try {
      final requestBody = jsonEncode(batch);

      await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-org-id': publicKey,
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Network error - fail silently
    }
  }

  /// Reset the flush timer
  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(batchInterval, () {
      flush();
    });
  }

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Dispose and cleanup
  void dispose() {
    _timer?.cancel();
    _queue.clear();
  }
}
