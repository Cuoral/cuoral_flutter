import 'package:cuoral_flutter/cuoral_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CuoralOverlayExample(),
    );
  }
}

class CuoralOverlayExample extends StatefulWidget {
  const CuoralOverlayExample({super.key});

  @override
  State<CuoralOverlayExample> createState() => _CuoralOverlayExampleState();
}

class _CuoralOverlayExampleState extends State<CuoralOverlayExample> {
  final String _publicKey = 'ENTER YOUR PUBLIC KEY HERE'; // Keep key here

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your normal app UI
        Scaffold(
          appBar: AppBar(
            title: const Text('Cuoral Integration Test App'),
          ), //Added Test App to the title
          body: Center(child: Text('Cuoral Integration Test App')),
        ),

        CuoralLauncher(
          publicKey: _publicKey,
          backgroundColor: Colors.blueAccent, //optional
          icon: const Icon(Icons.chat, color: Colors.white), //optional
          isVisible: true, //optional
          position: Alignment.bottomRight, //optional
        ),
      ],
    );
  }
}
