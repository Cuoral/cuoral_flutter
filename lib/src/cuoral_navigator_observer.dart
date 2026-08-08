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
      // Strategy 0: For PageRoute builders, try to infer target widget directly.
      // This avoids false positives like "MaterialPage" from route debug strings.
      final buildContext = route.subtreeContext;
      if (buildContext != null) {
        if (route is MaterialPageRoute<dynamic>) {
          final builtWidget = route.builder(buildContext);
          final widgetName = builtWidget.runtimeType.toString();
          if (_isValidScreenName(widgetName) &&
              !_isFrameworkWidget(widgetName) &&
              !_isRouteArtifactName(widgetName)) {
            return _toSnakeCase(widgetName);
          }
        }
      }

      // Strategy 1: Parse route.toString() FIRST (most reliable for unnamed routes)
      final routeString = route.toString();

      // Pattern 1: "MaterialPageRoute(...builder: BuildContext => WidgetName...)"
      // This catches the lambda arrow syntax
      var match = RegExp(r'=>\s*([A-Z][a-zA-Z0-9_]+)').firstMatch(routeString);
      if (match != null) {
        final pageName = match.group(1)!;
        if (_isValidScreenName(pageName) &&
            !_isFrameworkWidget(pageName) &&
            !_isRouteArtifactName(pageName)) {
          return _toSnakeCase(pageName);
        }
      }

      // Pattern 2: "MaterialPageRoute(...) → WidgetName"
      match = RegExp(r'→\s*([A-Z][a-zA-Z0-9_]+)').firstMatch(routeString);
      if (match != null) {
        final pageName = match.group(1)!;
        if (_isValidScreenName(pageName) &&
            !_isFrameworkWidget(pageName) &&
            !_isRouteArtifactName(pageName)) {
          return _toSnakeCase(pageName);
        }
      }

      // Pattern 3: Look for any Screen/Page/View class name in the route string
      match = RegExp(r'([A-Z][a-zA-Z0-9_]*(?:Screen|Page|View))').firstMatch(routeString);
      if (match != null) {
        final pageName = match.group(1)!;
        if (_isValidScreenName(pageName) &&
            !_isFrameworkWidget(pageName) &&
            !_isRouteArtifactName(pageName)) {
          return _toSnakeCase(pageName);
        }
      }

      // Strategy 2: Deep widget tree traversal (backup if string parsing fails)
      final subtreeContext = route.subtreeContext;
      if (subtreeContext != null) {
        final candidates = <String>[];

        // Deep traversal to collect ALL potential user widgets
        void visitor(Element element, int depth) {
          if (depth > 20) return; // Prevent infinite loops

          final widgetName = element.widget.runtimeType.toString();

          // Skip private/internal framework widgets
          if (!widgetName.startsWith('_') &&
              !_isFrameworkWidget(widgetName) &&
              !_isRouteArtifactName(widgetName) &&
              _isValidScreenName(widgetName)) {
            candidates.add(widgetName);
          }

          // Continue traversing children
          element.visitChildElements((child) => visitor(child, depth + 1));
        }

        subtreeContext.visitChildElements((e) => visitor(e, 0));

        // Pick the best candidate (prefer user widgets with common suffixes)
        if (candidates.isNotEmpty) {
          // Priority 1: Widgets ending with Screen, Page, View, Widget
          for (final candidate in candidates) {
            if (candidate.endsWith('Screen') ||
                candidate.endsWith('Page') ||
                candidate.endsWith('View') ||
                candidate.endsWith('Widget')) {
              return _toSnakeCase(candidate);
            }
          }

          // Priority 2: Longest non-generic name
          candidates.sort((a, b) => b.length.compareTo(a.length));
          for (final candidate in candidates) {
            final lower = candidate.toLowerCase();
            // Skip truly generic single-word names
            if (lower != 'body' && lower != 'content') {
              return _toSnakeCase(candidate);
            }
          }

          // Fallback: use the first one
          return _toSnakeCase(candidates.first);
        }
      }

      // Strategy 3: Inspect overlay entries
      if (route.overlayEntries.isNotEmpty) {
        for (final entry in route.overlayEntries) {
          final entryString = entry.toString();
          final entryMatch = RegExp(
            r'([A-Z][a-zA-Z0-9_]*(?:Screen|Page|View|Controller))',
          ).firstMatch(entryString);
          if (entryMatch != null) {
            final pageName = entryMatch.group(1)!;
            if (_isValidScreenName(pageName) &&
                !_isFrameworkWidget(pageName) &&
                !_isRouteArtifactName(pageName)) {
              return _toSnakeCase(pageName);
            }
          }
        }
      }

      // Strategy 4: Check route.settings.arguments for a screen name
      final args = route.settings.arguments;
      if (args is Map && args.containsKey('screenName')) {
        return _toSnakeCase(args['screenName'].toString());
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
      'PhysicalModel',
      'PhysicalShape',
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
      'Card',
      'Divider',
      'Drawer',
      'AppBar',
      'BottomNavigationBar',
      'FloatingActionButton',
      'IconButton',
      'TextButton',
      'ElevatedButton',
      'OutlinedButton',
      'TextField',
      'Image',
      'Icon',
      'Text',
      'RichText',
      'Wrap',
      'Flow',
      'Table',
      'TableCell',
      'GridView',
      'Hero',
      'InheritedWidget',
      'StatefulBuilder',
      'ValueListenableBuilder',
      'StreamBuilder',
      'FutureBuilder',
      'LayoutBuilder',
      'OrientationBuilder',
      'AspectRatio',
      'Baseline',
      'ConstraintsTransformBox',
      'CustomPaint',
      'BackdropFilter',
      'ShaderMask',
      'AnimatedContainer',
      'AnimatedOpacity',
      'AnimatedPadding',
      'AnimatedAlign',
      'AnimatedPositioned',
      'AnimatedSwitcher',
      'DecoratedBoxTransition',
      'ScaleTransition',
      'RotationTransition',
      'SizeTransition',
      'PositionedTransition',
    };
    return frameworkWidgets.contains(name);
  }

  /// Reject framework route/page artifacts that are not user screen names.
  bool _isRouteArtifactName(String name) {
    const artifacts = {
      'MaterialPage',
      'CupertinoPage',
      'NoTransitionPage',
      'Page',
      'RoutePage',
      'MaterialPageRoute',
      'CupertinoPageRoute',
    };
    if (artifacts.contains(name)) return true;
    if (name.endsWith('Route') || name.endsWith('Transition')) return true;
    return false;
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
