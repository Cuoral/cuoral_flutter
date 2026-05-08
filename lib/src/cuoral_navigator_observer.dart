import 'dart:async';
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
        route.settings.name != 'null' &&
        _isValidScreenName(route.settings.name!)) {
      _reportPageView(route.settings.name!);
      return;
    }

    // For unnamed routes, defer until after the frame is built
    // so the widget tree is available for inspection
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final screenName = _getScreenName(route);
      if (_isValidScreenName(screenName) && screenName != '/page') {
        _reportPageView(screenName);
        return;
      }

      // If still /page, the widget tree might not be ready yet.
      // Try once more after a short delay (route animation completing)
      Future.delayed(const Duration(milliseconds: 300), () {
        final retryName = _getScreenName(route);
        if (!_isValidScreenName(retryName)) return;
        _reportPageView(retryName);
      });
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
        route.settings.name != 'null' &&
        _isValidScreenName(route.settings.name!)) {
      return route.settings.name!;
    }

    // 2. For MaterialPageRoute without named routes, walk the widget tree
    if (route is ModalRoute) {
      final pageName = _extractPageName(route);
      if (pageName != null) {
        return '/$pageName';
      }
    }

    // 3. Fallback: route type
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

  /// Extract the page widget name from the route's widget tree
  String? _extractPageName(ModalRoute<dynamic> route) {
    try {
      // Strategy 1: Walk the widget tree (works after frame is built)
      final subtreeContext = route.subtreeContext;
      if (subtreeContext != null) {
        String? result;
        
        void visitor(Element element) {
          if (result != null) return;
          
          final widgetName = element.widget.runtimeType.toString();
          
          // Skip private/internal framework widgets
          if (widgetName.startsWith('_')) {
            element.visitChildElements(visitor);
            return;
          }
          
          // Skip known framework wrapper widgets
          if (_isFrameworkWidget(widgetName)) {
            element.visitChildElements(visitor);
            return;
          }
          
          // Found a user widget - use it
          if (_isValidScreenName(widgetName)) {
            result = _toSnakeCase(widgetName);
          }
        }
        
        subtreeContext.visitChildElements(visitor);
        if (result != null) return result;
      }

      // Strategy 2: Check route.settings.arguments for a screen name
      final args = route.settings.arguments;
      if (args is Map && args.containsKey('screenName')) {
        return args['screenName'].toString();
      }

      // Strategy 3: Try to parse route.toString() for page type info
      // MaterialPageRoute often contains the page name in its string representation
      final routeString = route.toString();
      final match = RegExp(r'→\s*(\w+)').firstMatch(routeString);
      if (match != null) {
        final pageName = match.group(1)!;
        if (_isValidScreenName(pageName) && !_isFrameworkWidget(pageName)) {
          return _toSnakeCase(pageName);
        }
      }
    } catch (_) {
      // Fail silently
    }
    return null;
  }

  /// Check if a widget name is a known framework widget
  bool _isFrameworkWidget(String name) {
    const frameworkWidgets = {
      'Builder',
      'Semantics',
      'Actions',
      'FocusScope',
      'FocusTraversalGroup',
      'PageStorage',
      'Offstage',
      'AnimatedBuilder',
      'FadeTransition',
      'FractionalTranslation',
      'SlideTransition',
      'RepaintBoundary',
      'Scaffold',
      'Material',
      'AnimatedPhysicalModel',
      'NotificationListener',
      'InheritedTheme',
      'IconTheme',
      'DefaultTextStyle',
      'CustomScrollView',
      'Scrollable',
      'ScrollNotificationObserver',
      'MediaQuery',
      'LayoutId',
      'CustomMultiChildLayout',
      'AnimatedDefaultTextStyle',
      'UnmanagedRestorationScope',
      'RestorationScope',
      'HeroControllerScope',
      'ScrollConfiguration',
      'PrimaryScrollController',
      'SafeArea',
      'Padding',
      'SizedBox',
      'Center',
      'Align',
      'Container',
      'DecoratedBox',
      'ColoredBox',
      'ConstrainedBox',
      'LimitedBox',
      'Expanded',
      'Flexible',
      'Column',
      'Row',
      'Stack',
      'Positioned',
      'ListView',
      'SingleChildScrollView',
      'ClipRect',
      'ClipRRect',
      'ClipPath',
      'Transform',
      'Opacity',
      'SliverList',
      'SliverPadding',
      'SliverFillRemaining',
      'KeyedSubtree',
      'TickerMode',
      'AbsorbPointer',
      'IgnorePointer',
      'BlockSemantics',
      'ExcludeSemantics',
      'MergeSemantics',
      'Listener',
      'GestureDetector',
      'InkWell',
      'Visibility',
    };
    return frameworkWidgets.contains(name);
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
