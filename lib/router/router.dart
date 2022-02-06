import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:odin/pages/home_page.dart';

@AdaptiveAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    RedirectRoute(path: '/home-page', redirectTo: '/'),
    CupertinoRoute(
      page: HomePage,
    ),
  ],
)
class $AppRouter {}
