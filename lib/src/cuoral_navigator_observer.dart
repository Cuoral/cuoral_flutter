import 'package:flutter/material.dart';
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

    final screenName = _getScreenName(route);
    if (!_isValidScreenName(screenName)) return;

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
    if (route.settings.name != null &&
        route.settings.name!.isNotEmpty &&
        _isValidScreenName(route.settings.name!)) {
      return route.settings.name!;
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
}
