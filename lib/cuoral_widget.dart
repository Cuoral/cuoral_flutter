// Ensure this is the first import related to InAppWebView
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cuoral_flutter/cuoral_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart'; // Other imports can follow
import 'package:permission_handler/permission_handler.dart';

class CuoralWidget extends StatefulWidget {
  final String publicKey;
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool showWidget;

  CuoralWidget({
    super.key,
    required this.publicKey,
    this.showWidget = true,
    this.firstName,
    this.lastName,
    this.email,
  }) : assert(publicKey.isNotEmpty, "publicKey must not be empty");

  @override
  State<CuoralWidget> createState() => _CuoralWidgetState();
}

class _CuoralWidgetState extends State<CuoralWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _sessionId;
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.locationWhenInUse.request();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showWidget) return const SizedBox();

    // Get current session ID from Cuoral SDK
    final sessionId = Cuoral.instance.sessionId;

    final Uri cuoralUri = Uri.parse(
      "https://js.cuoral.com/mobile.html",
    ).replace(
      queryParameters: {
        'auto_start': 'true',
        'key': widget.publicKey,
        'is_mobile': 'true',
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        if (sessionId != null) 'cuoral_mobile_session_id': sessionId,
        if (widget.email != null) 'email': widget.email!,
        if (widget.firstName != null) 'first_name': widget.firstName!,
        if (widget.lastName != null) 'last_name': widget.lastName!,
      },
    );

    return Stack(
      children: [
        if (_errorMessage != null)
          Center(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(cuoralUri.toString())),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
                useHybridComposition: true, // Android
                allowsInlineMediaPlayback: true, // iOS
                mediaPlaybackRequiresUserGesture: false,
                domStorageEnabled: true,
                databaseEnabled: true,
                supportZoom: false,
                builtInZoomControls: false,
                displayZoomControls: false,
                minimumZoomScale: 1.0,
                maximumZoomScale: 1.0,
              ),
              onWebViewCreated: (controller) {
                // Handler for setting session ID from WebView
                controller.addJavaScriptHandler(
                  handlerName: 'setSessionId',
                  callback: (args) {
                    setState(() {
                      _sessionId = args.first;
                    });
                  },
                );

                // Handler for native bridge messages from widget.js
                controller.addJavaScriptHandler(
                  handlerName: 'cuoralBridge',
                  callback: (args) async {
                    if (args.isEmpty) return null;

                    final message = args[0];
                    if (message is! Map) return null;

                    final type = message['type'];

                    if (type == 'CUORAL_START_RECORDING') {
                      // Start native screen recording
                      try {
                        final sessionId = message['sessionId'] ?? _sessionId;

                        // Don't start if already recording - this prevents the widget from
                        // calling START twice (once when user clicks, once when it receives STARTED message)
                        if (_isRecording) {
                          // Still notify widget that we're already recording
                          await controller.evaluateJavascript(
                            source: '''
                            if (window.handleCuoralNativeMessage) {
                              window.handleCuoralNativeMessage({
                                type: 'CUORAL_RECORDING_STARTED',
                                sessionId: '$sessionId',
                                timestamp: Date.now()
                              });
                            }
                          ''',
                          );
                          return null;
                        }

                        // Mark as recording BEFORE starting to prevent race condition
                        setState(() {
                          _isRecording = true;
                          _recordingStartTime = DateTime.now();
                        });

                        final success = await CuoralPlatform.instance
                            .startRecording(withAudio: true);

                        if (success) {
                          // Notify WebView that recording started
                          await controller.evaluateJavascript(
                            source: '''
                            if (window.handleCuoralNativeMessage) {
                              window.handleCuoralNativeMessage({
                                type: 'CUORAL_RECORDING_STARTED',
                                sessionId: '$sessionId',
                                timestamp: Date.now()
                              });
                            }
                          ''',
                          );
                        } else {
                          // Reset state on failure
                          setState(() {
                            _isRecording = false;
                            _recordingStartTime = null;
                          });

                          // Notify WebView of error
                          await controller.evaluateJavascript(
                            source: '''
                            if (window.handleCuoralNativeMessage) {
                              window.handleCuoralNativeMessage({
                                type: 'CUORAL_RECORDING_ERROR',
                                error: 'Failed to start recording - permission may be denied'
                              });
                            }
                          ''',
                          );
                        }
                      } catch (e) {
                        // Reset state on exception
                        setState(() {
                          _isRecording = false;
                          _recordingStartTime = null;
                        });

                        await controller.evaluateJavascript(
                          source: '''
                          if (window.handleCuoralNativeMessage) {
                            window.handleCuoralNativeMessage({
                              type: 'CUORAL_RECORDING_ERROR',
                              error: 'Exception: $e'
                            });
                          }
                        ''',
                        );
                      }
                    } else if (type == 'CUORAL_STOP_RECORDING') {
                      // Stop native screen recording
                      try {
                        // Only stop if we're actually recording
                        if (!_isRecording) {
                          return null;
                        }

                        // Check if minimum recording duration (2 seconds) has passed
                        // This ensures frames are captured
                        if (_recordingStartTime != null) {
                          final duration = DateTime.now().difference(
                            _recordingStartTime!,
                          );
                          if (duration.inMilliseconds < 2000) {
                            // Wait for minimum duration
                            await Future.delayed(
                              Duration(
                                milliseconds: 2000 - duration.inMilliseconds,
                              ),
                            );
                          }
                        }

                        final filePath =
                            await CuoralPlatform.instance.stopRecording();

                        // Reset recording state
                        setState(() {
                          _isRecording = false;
                          _recordingStartTime = null;
                        });

                        if (filePath != null && filePath.isNotEmpty) {
                          // Wait for the file to be fully written (iOS needs time to finalize)
                          // Retry up to 10 times with 500ms delays
                          File? videoFile;
                          int retries = 0;
                          const maxRetries = 10;

                          while (retries < maxRetries) {
                            final file = File(filePath);
                            if (await file.exists()) {
                              final fileSize = await file.length();

                              if (fileSize > 0) {
                                videoFile = file;
                                break;
                              }
                            }

                            retries++;
                            if (retries < maxRetries) {
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                            }
                          }

                          if (videoFile != null) {
                            try {
                              final bytes = await videoFile.readAsBytes();
                              final base64Video = base64Encode(bytes);
                              final fileName = filePath.split('/').last;

                              // Send CUORAL_RECORDING_COMPLETED with video data
                              await controller.evaluateJavascript(
                                source: '''
                                if (window.handleCuoralNativeMessage) {
                                  window.handleCuoralNativeMessage({
                                    type: 'CUORAL_RECORDING_COMPLETED',
                                    videoData: 'data:video/mp4;base64,$base64Video',
                                    fileName: '$fileName',
                                    filePath: '$filePath'
                                  });
                                }
                              ''',
                              );
                            } catch (e) {
                              await controller.evaluateJavascript(
                                source: '''
                                if (window.handleCuoralNativeMessage) {
                                  window.handleCuoralNativeMessage({
                                    type: 'CUORAL_RECORDING_ERROR',
                                    error: 'Failed to read video file: $e'
                                  });
                                }
                              ''',
                              );
                            }
                          } else {
                            await controller.evaluateJavascript(
                              source: '''
                              if (window.handleCuoralNativeMessage) {
                                window.handleCuoralNativeMessage({
                                  type: 'CUORAL_RECORDING_ERROR',
                                  error: 'Video file is empty or not ready'
                                });
                              }
                            ''',
                            );
                          }
                        } else {
                          await controller.evaluateJavascript(
                            source: '''
                            if (window.handleCuoralNativeMessage) {
                              window.handleCuoralNativeMessage({
                                type: 'CUORAL_RECORDING_ERROR',
                                error: 'Failed to stop recording - no file path returned. Check device logs for details.'
                              });
                            }
                          ''',
                          );
                        }
                      } catch (e) {
                        // Reset state on exception
                        setState(() {
                          _isRecording = false;
                          _recordingStartTime = null;
                        });

                        // Extract meaningful error message
                        String errorMessage = e.toString();
                        if (errorMessage.contains('Recording error:')) {
                          errorMessage = errorMessage.replaceFirst(
                            'Exception: Recording error:',
                            '',
                          );
                        }

                        await controller.evaluateJavascript(
                          source: '''
                          if (window.handleCuoralNativeMessage) {
                            window.handleCuoralNativeMessage({
                              type: 'CUORAL_RECORDING_ERROR',
                              error: 'Recording failed: $errorMessage'
                            });
                          }
                        ''',
                        );
                      }
                    }

                    return null;
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                });

                // Inject getSessionId function into the page
                await controller.evaluateJavascript(
                  source: '''
                  window.getSessionId = function() {
                    return window.__cuoral_session_id || null;
                  };
                ''',
                );

                // Execute JavaScript to get the session ID
                try {
                  final result = await controller.evaluateJavascript(
                    source: 'window.__cuoral_session_id || null',
                  );
                  if (result != null && result is String) {
                    _sessionId = result;
                  }
                } catch (e) {
                  // Fail silently
                }
              },
              onLoadError: (controller, url, code, message) {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      "Error loading Cuoral widget: $message (Code: $code)";
                });
              },
              onReceivedHttpError: (controller, request, response) {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      "HTTP Error loading Cuoral widget: ${response.statusCode} - ${response.reasonPhrase}";
                });
              },
              onPermissionRequest: (controller, request) async {
                if (request.resources.contains(
                  PermissionResourceType.GEOLOCATION,
                )) {
                  return Future.value(
                    PermissionRequestResponse(
                          resources: [
                            PermissionResourceType.GEOLOCATION.toString(),
                          ],
                          action: PermissionRequestResponseAction.GRANT,
                        )
                        as FutureOr<PermissionResponse?>?,
                  );
                }
                return Future.value(
                  PermissionRequestResponse(
                        resources:
                            request.resources
                                .map((resource) => resource.toString())
                                .toList(),
                        action: PermissionRequestResponseAction.DENY,
                      )
                      as FutureOr<PermissionResponse?>?,
                );
              },
              onConsoleMessage: (controller, consoleMessage) {
                // Suppress console messages
              },
              onJsPrompt: (controller, jsPromptRequest) async {
                return JsPromptResponse(message: '');
              },
              onGeolocationPermissionsShowPrompt: (controller, origin) async {
                // No change here, as the syntax is correct.
                // If it's still failing, it points to deeper environmental issues.
                return Future.value(
                  GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  ),
                );
              },
            ),
          ),
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(1),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
