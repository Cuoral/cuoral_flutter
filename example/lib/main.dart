import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cuoral_flutter/cuoral_flutter.dart';

void main() {
  // Wrap your app with error tracking
  CuoralErrorHandler.runApp(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Cuoral SDK
    await Cuoral.instance.initialize(
      publicKey: 'c8e3081e-8dfc-49b5-bbd1-4ef513504d88',
      email: 'demo@example.com',
      firstName: 'Demo',
      lastName: 'User',
    );

    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuoral Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Add Cuoral navigation observer for automatic screen tracking
      navigatorObservers: [CuoralNavigatorObserver()],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRecording = false;
  String? _recordingPath;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(_getTitle()),
          ),
          body: _getBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        // Cuoral Chat Launcher Button
        CuoralLauncher(
          publicKey: 'c8e3081e-8dfc-49b5-bbd1-4ef513504d88',
          email: 'demo@example.com',
          firstName: 'Demo',
          lastName: 'User',
        ),
      ],
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Cuoral Flutter Demo';
      case 1:
        return 'Settings';
      case 2:
        return 'Profile';
      default:
        return 'Cuoral Flutter Demo';
    }
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSettingsTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SDK Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SDK Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                          const SizedBox(height: 8),
                          Text('Initialized: ${Cuoral.instance.isInitialized}'),
                          Text(
                            'Session ID: ${Cuoral.instance.sessionId ?? "N/A"}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Intelligence Tracking Demos
                  const Text(
                    'Intelligence Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () {
                      // Manual page view tracking
                      Cuoral.instance.trackPageView('/demo_screen');
                      _showSnackBar('Page view tracked');
                    },
                    child: const Text('Track Page View'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      // Test error tracking
                      try {
                        throw Exception('This is a test error');
                      } catch (e, stackTrace) {
                        await CuoralErrorHandler.trackError(
                          e,
                          stackTrace,
                          context: 'demo_button',
                        );
                        _showSnackBar('Error tracked');
                      }
                    },
                    child: const Text('Track Test Error'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      // Test automatic network error tracking
                      // No need to use special HTTP client - ALL requests are tracked automatically
                      final client = HttpClient();
                      try {
                        final request = await client.getUrl(
                          Uri.parse('https://httpstat.us/404'),
                        );
                        final response = await request.close();
                        _showSnackBar(
                          'Network error automatically tracked (${response.statusCode})',
                        );
                      } catch (e) {
                        _showSnackBar('Network error tracked: $e');
                      } finally {
                        client.close();
                      }
                    },
                    child: const Text('Test Auto Network Tracking (404)'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      // Track a custom event
                      await Cuoral.instance.trackCustomEvent(
                        name: 'demo_button_clicked',
                        category: 'user_action',
                        properties: {
                          'button_name': 'Custom Event Demo',
                          'screen': 'home',
                          'timestamp': DateTime.now().toIso8601String(),
                        },
                        elementSelector: 'demo_custom_event_button',
                      );
                      _showSnackBar('Custom event tracked');
                    },
                    child: const Text('Track Custom Event'),
                  ),

                  const SizedBox(height: 16),

                  // Screen Recording Demo
                  const Text(
                    'Screen Recording',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _isRecording ? null : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start Recording'),
                  ),

                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Stop Recording'),
                  ),

                  if (_recordingPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Last recording: $_recordingPath',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Navigation Demo
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecondScreen(),
                          settings: const RouteSettings(name: '/second_screen'),
                        ),
                      );
                    },
                    child: const Text('Navigate to Second Screen'),
                  ),

                  const SizedBox(height: 16),

                  // Cuoral Chat Widget Demo
                  const Text(
                    'Chat Widget',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Look for the floating chat button in the bottom-right corner!',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      CuoralLauncher.open(
                        context,
                        publicKey: 'c8e3081e-8dfc-49b5-bbd1-4ef513504d88',
                        email: 'demo@example.com',
                        firstName: 'Demo',
                        lastName: 'User',
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Open Chat (Programmatic)'),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildSettingsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('This is the settings tab'),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Demo User'),
          const Text('demo@example.com'),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    print('DEBUG: _startRecording called');

    final isAvailable = await CuoralPlatform.instance.isRecordingAvailable();
    print('DEBUG: isRecordingAvailable = $isAvailable');

    if (!isAvailable) {
      _showSnackBar('Screen recording not available');
      return;
    }

    print('DEBUG: Calling CuoralPlatform.startRecording...');
    final success = await CuoralPlatform.instance.startRecording(
      withAudio: true,
    );
    print('DEBUG: startRecording returned: $success');

    if (success) {
      setState(() {
        _isRecording = true;
      });
      _showSnackBar('Recording started');
    } else {
      _showSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    print('DEBUG: _stopRecording called');
    final filePath = await CuoralPlatform.instance.stopRecording();
    print('DEBUG: stopRecording returned: $filePath');

    setState(() {
      _isRecording = false;
      _recordingPath = filePath;
    });

    if (filePath != null) {
      _showSnackBar('Recording saved');
    } else {
      _showSnackBar('Failed to save recording');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This is the second screen',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
