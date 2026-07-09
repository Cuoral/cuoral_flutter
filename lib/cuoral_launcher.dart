import 'package:cuoral_flutter/cuoral_widget.dart';
import 'package:flutter/material.dart';

/// Cuoral chat launcher widget
///
/// Displays a floating action button that opens the Cuoral chat interface.
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
  /// Use this when you want to open the chat from a custom button,
  /// a dedicated screen, or any user action.
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cuoral Chat",
      pageBuilder: (ctx, anim1, anim2) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            body: Center(
              child: GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 50.0,
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    elevation: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: CuoralWidget(
                              publicKey: publicKey,
                              showWidget: true,
                              email: email,
                              firstName: firstName,
                              lastName: lastName,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
          _showCuoralModal(context);
        },
        backgroundColor: widget.backgroundColor,
        child: widget.icon,
      ),
    );
  }

  void _showCuoralModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cuoral Chat",
      pageBuilder: (ctx, anim1, anim2) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            body: Center(
              child: GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 50.0,
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    elevation: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: CuoralWidget(
                              publicKey: widget.publicKey,
                              showWidget: true,
                              email: widget.email,
                              firstName: widget.firstName,
                              lastName: widget.lastName,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
