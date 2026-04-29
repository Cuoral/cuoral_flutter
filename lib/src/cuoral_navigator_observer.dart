import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'cuoral.dart';

/// Navigator observer that automatically tracks screen navigation
///
/// Add this to your MaterialApp or CupertinoApp:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [CuoralNavigatorObserver()],
///   // ...
/// );
/// ```
class CuoralNavigatorObserver extends NavigatorObserver {
  String? _lastValidScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackRoute(newRoute);
    }
  }

  void _trackRoute(Route<dynamic> route) {
    if (_shouldSkipRoute(route)) return;

    // Check if we already have a name (named route)
    if (route.settings.name != null &&
        route.settings.name!.isNotEmpty &&
        _isValidScreenName(route.settings.name!)) {
      _reportPageView(route.settings.name!);
      return;
    }

    // For unnamed routes, defer until after the frame is built
    // so the widget tree is available for inspection
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final screenName = _getScreenName(route);
      if (!_isValidScreenName(screenName)) return;
      _reportPageView(screenName);
    });
  }

  void _reportPageView(String screenName) {
    final referrer = _lastValidScreen;
    _lastValidScreen = screenName;
    Cuoral.instance.trackPageView(screenName, referrer: referrer);
  }

  bool _shouldSkipRoute(Route<dynamic> route) {
    if (route is RawDialogRoute ||
        route is DialogRoute ||
        route is PopupRoute ||
        (route is ModalRoute && !route.opaque)) {
      return true;
    }

    final routeType = route.runtimeType.toString();
    if (routeType.contains('Dialog') ||
        routeType.contains('BottomSheet') ||
        routeType.contains('Popup') ||
        routeType.contains('Snack') ||
        routeType.contains('Modal') ||
        routeType.contains('Overlay') ||
        routeType.contains('Menu')) {
      return true;
    }

    final settingsName = route.settings.name;
    if (settingsName != null) {
      final nameLower = settingsName.toLowerCase();
      if (nameLower.contains('dialog') ||
          nameLower.contains('popup') ||
          nameLower.contains('modal')) {
        return true;
      }
    }

    return false;
  }

  bool _isValidScreenName(String name) {
    if (name.contains('(') ||
        name.contains(')') ||
        name.contains('RouteSettings') ||
        name.contains('Controller') ||
        name.contains('animation') ||
        (name.contains('<') && name.contains('>')) ||
        name.contains('#')) {
      return false;
    }
    return true;
  }

  String _getScreenName(Route<dynamic> route) {
    // 1. Use named route if available
    if (route.settings.name != null &&
        route.settings.name!.isNotEmpty &&
        _isValidScreenName(route.settings.name!)) {
      return route.settings.name!;
    }

    // 2. For MaterialPageRoute/CupertinoPageRoute without named routes,
    //    try to extract the page widget class name from settings arguments or route toString
    if (route is ModalRoute) {
      final pageName = _extractPageName(route);
      if (pageName != null) {
        return '/$pageName';
      }
    }

    final routeType = route.runtimeType.toString();
    var cleanType = routeType;
    final genericStart = routeType.indexOf('<');
    if (genericStart != -1) {
      cleanType = routeType.substring(0, genericStart);
    }

    if (cleanType == 'MaterialPageRoute' ||
        cleanType.startsWith('_MaterialPageRoute')) {
      return '/page';
    } else if (cleanType == 'CupertinoPageRoute' ||
        cleanType.startsWith('_CupertinoPageRoute')) {
      return '/page';
    } else if (cleanType.contains('Dialog')) {
      return '/dialog';
    } else if (cleanType.contains('BottomSheet')) {
      return '/bottom_sheet';
    } else if (cleanType.contains('Popup') || cleanType.contains('Menu')) {
      return '/popup';
    }

    return '/${cleanType.toLowerCase()}';
  }

  /// Try to extract meaningful page name from a route
  /// Works with MaterialPageRoute(builder: (_) => MyScreen()) pattern
  String? _extractPageName(ModalRoute<dynamic> route) {
    try {
      // Get the current widget being displayed by the route
      final subtreeContext = route.subtreeContext;
      if (subtreeContext != null) {
        // Walk up to find the page widget (skip framework widgets)
        Element? pageElement;
        subtreeContext.visitChildElements((element) {
          if (pageElement != null) return;
          _findPageWidget(element, (found) {
            pageElement = found;
          });
        });

        if (pageElement != null) {
          final widgetName = pageElement!.widget.runtimeType.toString();
          if (_isValidScreenName(widgetName) && widgetName != 'Builder') {
            return _toSnakeCase(widgetName);
          }
        }
      }

      // Fallback: check route.settings.arguments for a screen name
      final args = route.settings.arguments;
      if (args is Map && args.containsKey('screenName')) {
        return args['screenName'].toString();
      }
    } catch (_) {
      // Fail silently
    }
    return null;
  }

  /// Recursively find the first non-framework widget (the page widget)
  void _findPageWidget(Element element, void Function(Element) onFound) {
    final widgetName = element.widget.runtimeType.toString();

    // Skip framework/internal widgets
    if (widgetName.startsWith('_') ||
        widgetName == 'Builder' ||
        widgetName == 'Semantics' ||
        widgetName == 'Actions' ||
        widgetName == 'FocusScope' ||
        widgetName == 'PageStorage' ||
        widgetName == 'Offstage' ||
        widgetName == 'AnimatedBuilder' ||
        widgetName == 'FadeTransition' ||
        widgetName == 'FractionalTranslation' ||
        widgetName == 'SlideTransition' ||
        widgetName == 'RepaintBoundary') {
      // Keep looking deeper
      element.visitChildElements((child) {
        _findPageWidget(child, onFound);
      });
      return;
    }

    // Found a user widget
    onFound(element);
  }

  /// Convert PascalCase to snake_case: "HomeScreen" → "home_screen"
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst('_', '');
  }
}
