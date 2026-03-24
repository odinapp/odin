import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:odin/pages/download/view.dart';
import 'package:odin/pages/home/home_page.dart';
import 'package:odin/pages/upload/view.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
        RedirectRoute(path: '/home-page', redirectTo: '/'),
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(path: '/upload', page: UploadRoute.page),
        AutoRoute(path: '/download', page: DownloadRoute.page),
      ];
}
