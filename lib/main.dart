import 'dart:async';
import 'dart:io';

// import 'package:better_open_file/better_open_file.dart';
import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odin/constants/theme.dart';
import 'package:odin/providers/booter_notifier.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/router/route_observer.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
// import 'package:odin/services/toast_service.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher_string.dart';

void main() async {
  if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
    TestWidgetsFlutterBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  // Initialize the app
  setupLocator();
  await locator<EnvironmentService>().init();

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          // ChangeNotifierProvider<FileNotifier>(create: (_) => FileNotifier()),
          ChangeNotifierProvider<DioNotifier>(create: (_) => locator<DioNotifier>()),
          ChangeNotifierProvider<BooterNotifier>(create: (_) => locator<BooterNotifier>()),
        ],
        child: const MyApp(),
      ),
    );
  }, (obj, stacktrace) {
    logger.e(obj, obj, stacktrace);
  });

  if (!kIsWeb && Platform.isWindows || Platform.isMacOS) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(720, 512);
      win.minSize = initialSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "Odin";
      win.show();
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void initDynamicLinks() async {
    // final toast = locator<ToastService>();
    // final fileNotifier = context.read<FileNotifier>();

    // FirebaseDynamicLinks.instance.onLink.listen(
    //   (PendingDynamicLinkData? dynamicLink) async {
    //     final Uri? deepLink = dynamicLink?.link;
    //     if (deepLink != null) {
    //       if (deepLink.pathSegments.isNotEmpty) {
    //         if (deepLink.pathSegments[0] == "files") {
    //           logger.i(deepLink.pathSegments.last);
    //           final String token = deepLink.pathSegments.last;
    //           final filePath = await fileNotifier.getFileFromToken(token.trim());
    //           if (Platform.isWindows || Platform.isMacOS) {
    //             launchUrlString(filePath);
    //           } else {
    //             toast.showMobileToast("Files saved in Downloads.");
    //             await OpenFile.open(filePath);
    //           }
    //         }
    //       }
    //     }
    //   },
    //   onError: (e) async {
    //     logger.e(e.message, e);
    //   },
    // );

    // final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    // final Uri? deepLink = data?.link;

    // if (deepLink != null) {
    //   if (deepLink.pathSegments.isNotEmpty) {
    //     if (deepLink.pathSegments[0] == "files") {
    //       logger.i(deepLink.pathSegments.last);
    //       final String token = deepLink.pathSegments.last;
    //       final filePath = await fileNotifier.getFileFromToken(token.trim());
    //       if (Platform.isWindows || Platform.isMacOS) {
    //         launchUrlString(filePath);
    //       } else {
    //         toast.showMobileToast("Files saved in Downloads.");
    //         await OpenFile.open(filePath);
    //       }
    //     }
    //   }
    // }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      if (Platform.isAndroid || Platform.isIOS) {
        initDynamicLinks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final OTheme theme = locator<OTheme>();
    final AppRouter appRouter = locator<AppRouter>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Odin - Open-source easy file sharing for everyone.',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.dark,
      routerDelegate: AutoRouterDelegate(
        appRouter,
        navigatorObservers: () => [AppRouteObserver()],
      ),
      routeInformationParser: appRouter.defaultRouteParser(),
    );
  }
}
