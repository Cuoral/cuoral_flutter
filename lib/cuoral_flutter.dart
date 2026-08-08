/// Cuoral Flutter SDK
///
/// A comprehensive mobile intelligence and screen recording SDK for Flutter.
///
/// Features:
/// - Customer intelligence tracking (page views, errors, network requests)
/// - Native crash tracking (Android & iOS)
/// - Screen recording with audio support
/// - Automatic error batching and queueing
///
/// Usage:
/// ```dart
/// void main() {
///   // Wrap your app with error tracking
///   CuoralErrorHandler.runApp(() async {
///     WidgetsFlutterBinding.ensureInitialized();
///
///     // Initialize Cuoral
///     await Cuoral.instance.initialize(
///       publicKey: 'your-public-key',
///       email: 'user@example.com',
///       firstName: 'John',
///       lastName: 'Doe',
///     );
///
///     runApp(MyApp());
///   });
/// }
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       // Add navigation observer to track screen views
///       navigatorObservers: [CuoralNavigatorObserver()],
///       home: HomeScreen(),
///     );
///   }
/// }
/// ```
library;

// Core SDK
export 'src/cuoral.dart' show Cuoral;
export 'src/intelligence.dart' show Intelligence;
export 'src/event_queue.dart' show EventQueue;

// Navigation tracking
export 'src/cuoral_navigator_observer.dart' show CuoralNavigatorObserver;

// Error handling
export 'src/cuoral_error_handler.dart' show CuoralErrorHandler;

// Platform interface
export 'src/cuoral_platform.dart' show CuoralPlatform;

// Widgets
export 'cuoral_widget.dart' show CuoralWidget;
export 'cuoral_launcher.dart' show CuoralLauncher;
export 'src/cuoral_overlay.dart' show CuoralOverlay;

/// Version information
const String version = '0.1.6';
