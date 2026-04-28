import 'package:flutter/material.dart';
import 'src/cuoral.dart';

class CuoralNavigationReporter extends NavigatorObserver {
  // Keep track of last valid screen for referrer
  String? _lastValidScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackPageView(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Track the screen we're going back to
    if (previousRoute != null) {
      _trackPageView(previousRoute, route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _trackPageView(newRoute, oldRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Don't track remove events
  }

  void _trackPageView(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Skip tracking for certain route types FIRST
    if (_shouldSkipRoute(route)) {
      return;
    }

    final screenName = _getScreenName(route);

    // Validate screen name before tracking
    if (!_isValidScreenName(screenName)) {
      return;
    }

    // Use last valid screen as referrer (never use dialogs/popups as referrers)
    final referrer = _lastValidScreen;

    // Update last valid screen
    _lastValidScreen = screenName;

    // Use the main Cuoral SDK to track the page view
    Cuoral.instance.trackPageView(screenName, referrer: referrer);
  }

  /// Validate that a screen name is a real route name, not a toString() output
  bool _isValidScreenName(String name) {
    // Reject toString() outputs and other invalid patterns
    if (name.contains('(') ||
        name.contains(')') ||
        name.contains('RouteSettings') ||
        name.contains('Controller') ||
        name.contains('animation') ||
        name.contains('<') && name.contains('>') ||
        name.contains('#')) {
      return false;
    }

    return true;
  }

  String _getScreenName(Route<dynamic> route) {
    // First try to get the route name from settings
    // But validate it's a real name, not a toString() output
    if (route.settings.name != null &&
        route.settings.name!.isNotEmpty &&
        _isValidScreenName(route.settings.name!)) {
      return route.settings.name!;
    }

    // Get just the runtime type name (not full toString)
    final routeType = route.runtimeType.toString();

    // Extract just the class name before any generic parameters or parentheses
    // e.g., "MaterialPageRoute<dynamic>" -> "MaterialPageRoute"
    // e.g., "RawDialogRoute<Object?>" -> "RawDialogRoute"
    var cleanType = routeType;
    final genericStart = routeType.indexOf('<');
    if (genericStart != -1) {
      cleanType = routeType.substring(0, genericStart);
    }

    // For common route types, return a friendly name
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

    // Return the clean type name as fallback
    // Lowercase and add leading slash
    return '/${cleanType.toLowerCase()}';
  }

  bool _shouldSkipRoute(Route<dynamic> route) {
    // Use type checking first (most reliable)
    if (route is RawDialogRoute ||
        route is DialogRoute ||
        route is PopupRoute ||
        route is ModalRoute && route.opaque == false) {
      return true;
    }

    final routeType = route.runtimeType.toString();

    // Skip dialogs, bottom sheets, popups, and overlays - these aren't real page views
    if (routeType.contains('Dialog') ||
        routeType.contains('BottomSheet') ||
        routeType.contains('Popup') ||
        routeType.contains('Snack') ||
        routeType.contains('Modal') ||
        routeType.contains('Overlay') ||
        routeType.contains('Menu')) {
      return true;
    }

    // Check settings name for dialog-like patterns
    final settingsName = route.settings.name;
    if (settingsName != null) {
      final nameLower = settingsName.toLowerCase();
      if (nameLower.contains('dialog') ||
          nameLower.contains('popup') ||
          nameLower.contains('modal') ||
          nameLower.contains('routesettings')) {
        return true;
      }
    }

    return false;
  }
}
