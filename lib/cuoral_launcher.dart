import 'package:flutter/material.dart';
import 'src/cuoral_overlay.dart';

/// Cuoral chat launcher widget
///
/// Displays a floating action button that opens the Cuoral chat interface.
/// Uses [CuoralOverlay] for smooth slide-up animation and pre-warmed WebView.
class CuoralLauncher extends StatefulWidget {
  final String publicKey;
  final String? email;
  final String? firstName;
  final String? lastName;

  final Color backgroundColor;
  final Icon icon;
  final bool isVisible;
  final Alignment position;

  const CuoralLauncher({
    super.key,
    required this.publicKey,
    this.backgroundColor = Colors.blueAccent,
    this.icon = const Icon(Icons.chat),
    this.isVisible = true,
    this.position = Alignment.bottomRight,
    this.email,
    this.firstName,
    this.lastName,
  });

  /// Open the Cuoral chat programmatically from anywhere.
  ///
  /// Uses a smooth slide-up animation with a pre-warmed WebView.
  /// The WebView stays cached for 30 minutes for instant re-opens.
  ///
  /// Example:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () {
  ///     CuoralLauncher.open(
  ///       context,
  ///       publicKey: 'your-public-key',
  ///       email: 'user@example.com',
  ///     );
  ///   },
  ///   child: Text('Contact Support'),
  /// );
  /// ```
  static void open(
    BuildContext context, {
    required String publicKey,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    CuoralOverlay.instance.show(
      context,
      publicKey: publicKey,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Close the Cuoral chat overlay programmatically.
  static void close() {
    CuoralOverlay.instance.hide();
  }

  @override
  State<CuoralLauncher> createState() => _CuoralLauncherState();
}

class _CuoralLauncherState extends State<CuoralLauncher> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox();
    }

    return Positioned(
      bottom: widget.position == Alignment.bottomRight ? 30 : null,
      right: widget.position == Alignment.bottomRight ? 20 : null,
      top: widget.position == Alignment.topRight ? 30 : null,
      left: widget.position == Alignment.topLeft ? 20 : null,
      child: FloatingActionButton(
        onPressed: () {
          CuoralOverlay.instance.show(
            context,
            publicKey: widget.publicKey,
            email: widget.email,
            firstName: widget.firstName,
            lastName: widget.lastName,
          );
        },
        backgroundColor: widget.backgroundColor,
        child: widget.icon,
      ),
    );
  }
}
