import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';

class CuoralWidget extends StatefulWidget {
  final String publicKey;
  final bool showWidget;

  CuoralWidget({super.key, required this.publicKey, this.showWidget = true})
    : assert(publicKey.isNotEmpty, "publicKey must not be empty");

  @override
  State<CuoralWidget> createState() => _CuoralWidgetState();
}

class _CuoralWidgetState extends State<CuoralWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();

    // Initialize WebView after the widget has been built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Delay JavaScript mode setting to ensure WebView is initialized
        await _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
        await _webViewController.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (_) {
              Future.delayed(Duration(seconds: 5), () {
                // wait for 4 seconds so widget can be fully loaded
                setState(() {
                  _isLoading = false;
                });
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    "Error loading Cuoral widget: ${error.description}";
              });
              if (kDebugMode) {
                print("WebView Error: ${error.description}");
              }
            },
            onNavigationRequest: (_) => NavigationDecision.navigate,
          ),
        );
        _loadCuoralWidget();
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error initializing WebView: $e";
        });
        if (kDebugMode) {
          print("Error initializing WebView: $e");
        }
      }
    });
  }

  void _loadCuoralWidget() {
    try {
      _webViewController.loadRequest(
        Uri.parse(
          "https://js.cuoral.com/mobile.html?auto_display=true&key=${widget.publicKey}",
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load Cuoral widget: $e";
      });
      if (kDebugMode) {
        print("Error loading HTML: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showWidget) return const SizedBox();

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
            child: WebViewWidget(controller: _webViewController),
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
