// Ensure this is the first import related to InAppWebView
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart'; // Other imports can follow
import 'package:flutter/foundation.dart';
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
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

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

    final Uri cuoralUri = Uri.parse(
      "https://js.cuoral.com/mobile.html",
    ).replace(
      queryParameters: {
        'auto_display': 'true',
        'key': widget.publicKey,
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
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
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
                if (kDebugMode) {
                  print(
                    "InAppWebView HTTP Error: ${response.statusCode} - ${response.reasonPhrase}",
                  );
                }
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
                if (kDebugMode) {
                  print("WEB CONSOLE: ${consoleMessage.message}");
                }
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
