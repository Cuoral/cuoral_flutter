# Cuoral Flutter SDK Integration Guide

## Overview

This document provides a step-by-step guide on how to integrate the **Cuoral Flutter SDK** into your Flutter application. Cuoral is a customer engagement and support solution that allows businesses to add customer support widgets to their mobile applications, enabling real-time communication with users.

The Cuoral Flutter SDK provides a widget that can be easily added to any Flutter app, allowing businesses to create a seamless support experience. This guide will walk you through the installation and integration process.

---

## Prerequisites

Before integrating the Cuoral Flutter SDK, make sure you have the following:

1. **Flutter SDK**: Ensure you have Flutter installed on your machine. You can download and install Flutter from the official website: [Flutter Installation](https://flutter.dev/docs/get-started/install).

2. **Cuoral Account**: You need to have a Cuoral account to obtain a **public key** for integration. If you haven't already, sign up for a Cuoral account on the official website.

---

## Installation

1. **Add Cuoral Flutter SDK to `pubspec.yaml`**

   To begin, you need to add the `cuoral_flutter` package to your Flutter project. Open your `pubspec.yaml` file and add the following line under the dependencies section:

   ```yaml
   dependencies:
     cuoral_flutter: ^0.0.1  # Replace with the latest version
   ```

2. **Install the dependencies**:
   Run the following command in your terminal to install the Cuoral SDK:

   ```bash
   flutter pub get
   ```

---

## Basic Usage

### 1. **Import the Cuoral SDK**

Import the `cuoral_flutter` package into the Dart file where you want to use the Cuoral widget.

```dart
import 'package:cuoral_flutter/cuoral_flutter.dart';
```

### 2. **Create a Widget with Cuoral Overlay**

The main feature of the Cuoral SDK is the floating widget (or button) that launches the customer support interface. You can customize this widget and position it anywhere on the screen.

Here's an example implementation that demonstrates how to integrate the Cuoral overlay widget into your app.

```dart
import 'package:flutter/material.dart';
import 'package:cuoral_flutter/cuoral_flutter.dart';

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
          ),
          body: const Center(child: Text('Cuoral Integration Test App')),
        ),

        // Cuoral Launcher Widget
        CuoralLauncher(
          publicKey: _publicKey,
          backgroundColor: Colors.blueAccent, // Optional: Background color of the widget
          icon: const Icon(Icons.chat, color: Colors.white), // Optional: Icon of the widget
          isVisible: true, // Optional: Set visibility of the widget
          position: Alignment.bottomRight, // Optional: Position of the widget
        ),
      ],
    );
  }
}
```

### Key Configuration Options:

* **`publicKey`**: Replace with your Cuoral public key (required for integration).
* **`backgroundColor`**: (Optional) Set the background color of the widget. The default is transparent.
* **`icon`**: (Optional) Set the icon that appears on the floating button.
* **`isVisible`**: (Optional) Control the visibility of the widget. Default is `true` (visible).
* **`position`**: (Optional) Set the position of the widget on the screen. You can use any `Alignment` value (e.g., `Alignment.bottomRight`, `Alignment.topLeft`).

---

## Advanced Usage

### Customizing Widget Behavior

If you want to customize the widget behavior further, you can control its visibility dynamically using state management (e.g., `setState`).

```dart
setState(() {
  isVisible = false; // Dynamically hide the widget
});
```

---

## Error Handling & Logging

To enable logging and better error handling, you can use the following:

```dart
CuoralFlutter.initialize(
  key: _publicKey,
  autoDisplay: true,
  position: WidgetPosition.bottomRight,
);
```

This helps to initialize the Cuoral SDK properly and ensures that any initialization errors are captured.

---

## Testing the Integration

Once you have integrated the Cuoral widget, run your app on a real device or emulator and check that the widget displays correctly.

1. Ensure the widget shows at the specified position on the screen.
2. Tap on the widget to check if the customer support interface opens.
3. Confirm that the widget interacts with the Cuoral backend by sending and receiving messages.

---

## FAQ

### 1. **How do I get my Cuoral public key?**

* You can get your public key by logging into your Cuoral account and navigating to the integration page.

### 2. **How can I change the appearance of the Cuoral widget?**

* You can customize the widget’s appearance by adjusting properties like `backgroundColor`, `icon`, and `position`.

### 3. **Can I use Cuoral in production apps?**

* Yes, the Cuoral SDK is ready for production use. However, ensure you follow best practices in terms of securing and managing your public and private keys.

---

## Conclusion

The Cuoral Flutter SDK allows for seamless integration of customer support functionality into your Flutter applications. By following this guide, you can easily set up the floating widget and customize it to fit your needs. If you encounter any issues, refer to the official Cuoral documentation or contact their support team.

For more information, visit the official [Cuoral Website](https://cuoral.com).

---

This should be enough to help you integrate and customize the Cuoral SDK in your Flutter application!
