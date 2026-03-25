import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:odin/services/logger.dart';

class AppRouteObserver extends AutoRouterObserver {
  final _routes = <String>[];
  @override
  void didPush(Route route, Route? previousRoute) {
    _routes.add(route.settings.name.toString());
    logger.i(_routes.join(' ➡️ '));
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _routes.removeLast();
    logger.w('⬅️ ${route.settings.name}');
  }
}
