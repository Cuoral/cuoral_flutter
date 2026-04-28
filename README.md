# Cuoral Flutter SDK

## What is Cuoral?

Cuoral is a complete customer engagement and support platform that helps you understand and support your mobile app users. The Flutter SDK provides:

- **💬 Live Chat Widget**: Real-time customer support conversations
- **📊 Customer Intelligence**: Automatic tracking of user behavior, errors, and interactions
- **📹 Session Recording**: Capture screen recordings to understand user issues
- **🔍 Error Monitoring**: Automatic crash detection and network error tracking
- **📈 Custom Analytics**: Track business-specific events and conversions

## Key Features

### Automatic Intelligence Tracking
- ✅ **Page Views**: Track screen navigation automatically
- ✅ **Network Errors**: Capture all 4xx/5xx API responses
- ✅ **Console Errors**: Log unhandled exceptions and crashes
- ✅ **Native Crashes**: Report iOS and Android native crashes
- ✅ **Session Management**: Persistent user sessions across app restarts

### Customer Support Features
- ✅ **Floating Chat Button**: Customizable support widget
- ✅ **Screen Recording**: Record user sessions with permission
- ✅ **User Profiles**: Associate support conversations with user data
- ✅ **Custom Events**: Track business-specific user actions

### Developer Experience
- ✅ **Zero Configuration Tracking**: Works automatically after initialization
- ✅ **Graceful Degradation**: Never crashes your app if backend is unavailable
- ✅ **Event Batching**: Efficient network usage with automatic batching
- ✅ **Privacy First**: User consent required for screen recording

---

## Prerequisites

Before integrating the Cuoral Flutter SDK, ensure you have:

1. **Flutter SDK**: Version 3.7.0 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
2. **Cuoral Account**: Sign up at [cuoral.com](https://cuoral.com) to get your public key
3. **Platform Support**: iOS 12+ and Android API 21+

---

## Installation

### 1. Add Dependency

Add `cuoral_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  cuoral_flutter: ^0.0.1  # Check pub.dev for latest version
```

### 2. Install Packages

```bash
flutter pub get
```

### 3. Platform-Specific Setup

#### iOS Setup

Add the following to your `ios/Podfile`:

```ruby
platform :ios, '12.0'  # Minimum iOS 12
```

Run pod install:

```bash
cd ios && pod install && cd ..
```

#### Android Setup

Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34  # Minimum API 21 required
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## Quick Start

### 1. Initialize the SDK

Initialize Cuoral in your `main()` function **before** running your app:

```dart
import 'package:flutter/material.dart';
import 'package:cuoral_flutter/cuoral_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Cuoral SDK
  await Cuoral.instance.initialize(
    publicKey: 'your-public-key-here',
    email: 'user@example.com',      // Optional: User email
    firstName: 'John',               // Optional: User first name
    lastName: 'Doe',                 // Optional: User last name
  );
  
  // Run your app with error handling
  CuoralErrorHandler.runApp(() {
    runApp(const MyApp());
  });
}
```

### 2. Add Navigation Observer

Track page views automatically by adding `CuoralNavigatorObserver` to your `MaterialApp`:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      navigatorObservers: [
        CuoralNavigationObserver(), // Automatically tracks page views
      ],
      home: const HomePage(),
    );
  }
}
```

### 3. Add the Chat Widget

Add the floating chat button to your main screen:

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your app UI
        Scaffold(
          appBar: AppBar(title: const Text('My App')),
          body: const Center(child: Text('Welcome!')),
        ),
        
        // Cuoral floating chat button
        CuoralLauncher(
          publicKey: 'your-public-key-here',
          email: 'user@example.com',
          firstName: 'John',
          lastName: 'Doe',
        ),
      ],
    );
  }
}
```

That's it! Your app now has:
- ✅ Automatic page view tracking
- ✅ Automatic error tracking
- ✅ Automatic network error tracking
- ✅ Live chat support widget

---

## Customer Intelligence & Analytics

The Cuoral SDK automatically collects user behavior data to help you understand and support your customers better. All data is batched efficiently to minimize network impact.

### Automatic Tracking (Zero Code Required)

Once initialized, these events are tracked automatically:

#### 1. **Page Views**
Every screen navigation is tracked with the `CuoralNavigatorObserver`:

```dart
MaterialApp(
  navigatorObservers: [
    CuoralNavigationObserver(),
  ],
  // ...
)
```

Named routes are preferred for cleaner analytics:
```dart
Navigator.pushNamed(context, '/product-details');  // Tracked as "/product-details"
```

#### 2. **Network Errors**
All HTTP requests are automatically intercepted. Errors (4xx, 5xx) are tracked with:
- Request URL and method
- Response status code
- Error message
- Request/response duration
- Request and response bodies

**No manual HTTP client required** - works with all HTTP packages automatically!

#### 3. **Console Errors**
Unhandled exceptions are tracked when you use `CuoralErrorHandler.runApp()`:

```dart
void main() async {
  await Cuoral.instance.initialize(publicKey: 'your-key');
  
  CuoralErrorHandler.runApp(() {
    runApp(const MyApp());
  });
}
```

Captured information:
- Error message and type
- Full stack trace
- Screen where error occurred
- Device and OS information

#### 4. **Native Crashes**
iOS and Android native crashes are automatically reported with:
- Crash stack trace
- Device model and OS version
- App version
- Session ID for reproduction

### Custom Events

Track business-specific events and user actions:

```dart
// E-commerce example
await Cuoral.instance.trackCustomEvent(
  name: 'add_to_cart',
  category: 'conversion',
  properties: {
    'product_id': 'SKU-12345',
    'product_name': 'Blue Widget',
    'price': 29.99,
    'quantity': 2,
    'category': 'widgets',
  },
  elementSelector: 'add_to_cart_button',
);

// Feature usage
await Cuoral.instance.trackCustomEvent(
  name: 'filter_applied',
  category: 'engagement',
  properties: {
    'filter_type': 'price_range',
    'min_price': 10,
    'max_price': 100,
  },
);

// User preferences
await Cuoral.instance.trackCustomEvent(
  name: 'theme_changed',
  category: 'preferences',
  properties: {
    'new_theme': 'dark',
    'previous_theme': 'light',
  },
);
```

#### Recommended Event Categories

| Category | Use For | Examples |
|----------|---------|----------|
| `user_action` | Button clicks, gestures | `button_clicked`, `swipe_action` |
| `conversion` | Business goals | `signup_completed`, `purchase_made` |
| `engagement` | Feature usage | `video_played`, `search_performed` |
| `preferences` | Settings changes | `notifications_enabled`, `language_changed` |

### Manual Event Tracking

For more control, you can manually track events:

```dart
// Track specific page view
await Cuoral.instance.trackPageView(
  '/checkout/payment',
  referrer: '/checkout/shipping',
);

// Track custom error
await Cuoral.instance.trackConsoleError(
  message: 'Payment validation failed',
  stackTrace: stackTrace.toString(),
  logLevel: 'error',
);

// Track network error manually
await Cuoral.instance.trackNetworkError(
  url: 'https://api.example.com/payment',
  method: 'POST',
  status: 400,
  duration: 1234,
  error: 'Invalid card number',
);
```

### Event Batching

Events are automatically batched for efficiency:
- **Batch size**: Up to 10 events per request
- **Batch interval**: 2 seconds
- **Max queue**: 30 events (oldest removed if exceeded)

To force immediate sending (e.g., before app closes):

```dart
await Cuoral.instance.flush();
```

### Viewing Your Analytics

All tracked events appear in your Cuoral dashboard:
1. Log in to [app.cuoral.com](https://app.cuoral.com)
2. Navigate to **Intelligence** → **Page Views** / **Errors** / **Custom Events**
3. Filter by session, user, or date range
4. Click any event to see full details

---

## Screen Recording

Enable users to record their screens when reporting issues. Requires explicit user permission.

### How It Works

1. User clicks record button in chat widget
2. System permission dialog appears (iOS/Android)
3. Recording starts after permission granted
4. Recording stops automatically or manually
5. Video is attached to support conversation

### Implementation

Screen recording is built into the chat widget - no additional code needed! Users can:
- Start recording from the chat interface
- Stop recording when done
- Video automatically uploads to support conversation

### Privacy & Permissions

**iOS**: Requires `NSMicrophoneUsageDescription` in `Info.plist` if recording with audio:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Record screen with audio to help support team understand your issue</string>
```

**Android**: Requires `FOREGROUND_SERVICE` permission (automatically added by SDK)

### Programmatic Recording

You can also trigger recording from your code:

```dart
// Check if recording is available
bool available = await CuoralPlatform.instance.isRecordingAvailable();

if (available) {
  // Start recording
  await CuoralPlatform.instance.startRecording(withAudio: true);
  
  // Stop recording after some time
  await Future.delayed(Duration(seconds: 30));
  String? filePath = await CuoralPlatform.instance.stopRecording();
  
  print('Recording saved to: $filePath');
}
```

---

## Widget Customization

### CuoralLauncher Options

```dart
CuoralLauncher(
  publicKey: 'your-key',
  
  // User Information (optional but recommended)
  email: 'user@example.com',
  firstName: 'John',
  lastName: 'Doe',
  
  // Visual Customization
  backgroundColor: Colors.blue,           // Button background color
  icon: Icon(Icons.support_agent),       // Button icon
  position: Alignment.bottomRight,        // Button position
  
  // Behavior
  showWidget: true,                       // Show/hide button
)
```

### Alternative: Inline Widget

Embed the chat directly in your UI instead of floating button:

```dart
CuoralWidget(
  publicKey: 'your-key',
  email: 'user@example.com',
  firstName: 'John',
  lastName: 'Doe',
  showWidget: true,
)
```

---

## Session Management

### How Sessions Work

- **Persistent**: Sessions are saved locally and persist across app restarts
- **30-Day Expiry**: Sessions automatically expire after 30 days
- **Automatic Creation**: First time users get a new session automatically
- **Profile Association**: User info (email, name) attached to sessions

### Setting User Profile

Update user information after login:

```dart
await Cuoral.instance.initialize(
  publicKey: 'your-key',
  email: user.email,
  firstName: user.firstName,
  lastName: user.lastName,
);
```

The SDK automatically associates this information with the user's session.

### Session Lifecycle

```dart
// Initialize (creates or loads session)
await Cuoral.instance.initialize(publicKey: 'your-key');

// Session ID is automatically managed
// Access it if needed:
String? sessionId = Cuoral.instance.sessionId;

// Clear session on logout
await Cuoral.instance.clearSession();
```

---

## Error Handling & Best Practices

### Graceful Degradation

The SDK never crashes your app:
- If Cuoral servers are down (502, 504), the SDK continues with cached session
- Network errors are logged but don't interrupt app functionality
- All SDK methods are non-blocking

### Best Practices

#### ✅ DO

```dart
// Initialize early in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Cuoral.instance.initialize(publicKey: 'your-key');
  CuoralErrorHandler.runApp(() => runApp(MyApp()));
}

// Use named routes for better analytics
Navigator.pushNamed(context, '/product-details');

// Track important business events
await Cuoral.instance.trackCustomEvent(
  name: 'purchase_completed',
  category: 'conversion',
  properties: {'order_id': orderId, 'amount': amount},
);
```

#### ❌ DON'T

```dart
// Don't initialize multiple times
await Cuoral.instance.initialize(...);
await Cuoral.instance.initialize(...); // ❌

// Don't track sensitive data
await Cuoral.instance.trackCustomEvent(
  properties: {
    'credit_card': '1234-5678-9012-3456', // ❌ Never track PII
    'password': 'secret123',               // ❌
  },
);

// Don't manually wrap HTTP clients
// ❌ The SDK automatically tracks all requests
final client = CuoralHttpClient(http.Client());
```

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
