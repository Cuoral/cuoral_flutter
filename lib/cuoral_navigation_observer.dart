import 'package:cuoral_flutter/cuoral_navigation_reporter.dart';
import 'package:flutter/material.dart';

class CuoralNavigationObserver extends NavigatorObserver {
  final _reporter = CuoralNavigationReporter();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reporter.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reporter.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _reporter.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reporter.didRemove(route, previousRoute);
  }
}
