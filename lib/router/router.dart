import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:odin/pages/home/home_page.dart';
import 'package:odin/pages/upload/view.dart';

part 'router.gr.dart';

@AdaptiveAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    RedirectRoute(path: '/home-page', redirectTo: '/'),
    AutoRoute(
      initial: true,
      page: HomePage,
    ),
    AutoRoute(
      path: '/upload',
      page: UploadPage,
    ),
  ],
)
class AppRouter extends _$AppRouter {}
