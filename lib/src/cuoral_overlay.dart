import 'package:flutter/material.dart';
import '../cuoral_widget.dart';

/// Singleton overlay manager for the Cuoral chat widget.
///
/// Keeps the WebView alive between opens for instant display.
/// Pre-warms on first call so subsequent opens are near-instant.
/// Reloads the page after 30 minutes to pick up remote updates.
class CuoralOverlay {
  static final CuoralOverlay _instance = CuoralOverlay._internal();
  static CuoralOverlay get instance => _instance;

  CuoralOverlay._internal();

  // Configuration
  String? _publicKey;
  String? _email;
  String? _firstName;
  String? _lastName;

  // State
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;
  bool _isPreWarmed = false;
  GlobalKey<_CuoralOverlayWidgetState>? _widgetKey;
  bool _isInitialized = false;

  /// Whether the overlay is currently visible
  bool get isVisible => _isVisible;

  /// Whether the WebView has been pre-warmed
  bool get isPreWarmed => _isPreWarmed;

  /// Pre-warm the WebView in the background.
  ///
  /// Call this after SDK initialization so the widget is ready
  /// when the user wants to open chat.
  void preWarm({
    required String publicKey,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    _publicKey = publicKey;
    _email = email;
    _firstName = firstName;
    _lastName = lastName;
    _isPreWarmed = true;
  }

  /// Show the Cuoral chat overlay with slide-up animation.
  void show(
    BuildContext context, {
    String? publicKey,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    if (_isVisible) return;

    // Update config if provided
    if (publicKey != null) _publicKey = publicKey;
    if (email != null) _email = email;
    if (firstName != null) _firstName = firstName;
    if (lastName != null) _lastName = lastName;

    if (_publicKey == null || _publicKey!.isEmpty) return;

    // Create the overlay entry only once
    if (!_isInitialized) {
      _widgetKey = GlobalKey<_CuoralOverlayWidgetState>();

      _overlayEntry = OverlayEntry(
        builder:
            (context) => _CuoralOverlayWidget(
              key: _widgetKey,
              publicKey: _publicKey!,
              email: _email,
              firstName: _firstName,
              lastName: _lastName,
              onClose: hide,
            ),
      );

      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
      _isInitialized = true;
    }

    _isVisible = true;

    // Trigger the slide-up animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetKey?.currentState?._animateIn();
    });
  }

  /// Hide the overlay with slide-down animation.
  void hide() {
    if (!_isVisible) return;

    _isVisible = false;
    _widgetKey?.currentState?._animateOut();
  }

  /// Force reload the WebView content (e.g., after a remote update).
  void forceReload() {
    _widgetKey?.currentState?._reloadWebView();
  }

  /// Dispose the overlay (cleanup when app closes).
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
    _isInitialized = false;
  }
}

/// Internal overlay widget with animation
class _CuoralOverlayWidget extends StatefulWidget {
  final String publicKey;
  final String? email;
  final String? firstName;
  final String? lastName;
  final VoidCallback onClose;

  const _CuoralOverlayWidget({
    super.key,
    required this.publicKey,
    this.email,
    this.firstName,
    this.lastName,
    required this.onClose,
  });

  @override
  State<_CuoralOverlayWidget> createState() => _CuoralOverlayWidgetState();
}

class _CuoralOverlayWidgetState extends State<_CuoralOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from bottom
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateIn() {
    _animationController.forward();
  }

  void _animateOut() {
    _animationController.reverse();
  }

  void _reloadWebView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Don't render if completely hidden
        if (_animationController.value == 0.0) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Backdrop
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.4 * _fadeAnimation.value,
                ),
              ),
            ),

            // Chat panel - slide up from bottom
            Positioned(
              top: topPadding + 20,
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  elevation: 16,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // WebView
                      CuoralWidget(
                        publicKey: widget.publicKey,
                        email: widget.email,
                        firstName: widget.firstName,
                        lastName: widget.lastName,
                        showWidget: true,
                      ),
                      // Floating close button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black87,
                            ),
                            onPressed: widget.onClose,
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
