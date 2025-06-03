import 'package:cuoral_flutter/cuoral_widget.dart';
import 'package:flutter/material.dart';

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
    this.backgroundColor = Colors.blueAccent, // Default background color
    this.icon = const Icon(Icons.chat), // Default icon
    this.isVisible = true, // Default to visible
    this.position = Alignment.bottomRight,
    this.email,
    this.firstName,
    this.lastName, // Default position
  });

  @override
  // ignore: library_private_types_in_public_api
  _CuoralLauncherState createState() => _CuoralLauncherState();
}

class _CuoralLauncherState extends State<CuoralLauncher> {
  @override
  Widget build(BuildContext context) {
    // Only display the FAB if isVisible is true
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
        child: widget.icon,
        backgroundColor: widget.backgroundColor,
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
            backgroundColor: Colors.black.withOpacity(0.4),
            body: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing the modal
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 50.0,
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // Rounded corners here
                    elevation: 10, // Optional: adds a shadow
                    child: ClipRRect(
                      // Clip the content to fit within the rounded corners
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
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
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
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }
}
