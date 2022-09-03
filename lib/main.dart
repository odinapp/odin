import 'dart:async';
import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odin/constants/theme.dart';
import 'package:odin/pages/home_page.dart';
import 'package:odin/providers/file_notifier.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/toast_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    TestWidgetsFlutterBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  // Initialize the app
  await dotenv.load();
  setupLocator();

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FileNotifier>(create: (_) => FileNotifier()),
        ],
        child: const MyApp(),
      ),
    );
  }, (obj, stacktrace) {
    logger.e(obj, obj, stacktrace);
  });

  if (Platform.isWindows || Platform.isMacOS) {
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
    final toast = locator<ToastService>();
    final fileNotifier = context.read<FileNotifier>();

    FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData? dynamicLink) async {
        final Uri? deepLink = dynamicLink?.link;
        if (deepLink != null) {
          if (deepLink.pathSegments.isNotEmpty) {
            if (deepLink.pathSegments[0] == "files") {
              logger.i(deepLink.pathSegments.last);
              final String token = deepLink.pathSegments.last;
              final filePath = await fileNotifier.getFileFromToken(token.trim());
              if (Platform.isWindows || Platform.isMacOS) {
                launchUrlString(filePath);
              } else {
                toast.showMobileToast("Files saved in Downloads.");
                await OpenFile.open(filePath);
              }
            }
          }
        }
      },
      onError: (e) async {
        logger.e(e.message, e);
      },
    );

    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      if (deepLink.pathSegments.isNotEmpty) {
        if (deepLink.pathSegments[0] == "files") {
          logger.i(deepLink.pathSegments.last);
          final String token = deepLink.pathSegments.last;
          final filePath = await fileNotifier.getFileFromToken(token.trim());
          if (Platform.isWindows || Platform.isMacOS) {
            launchUrlString(filePath);
          } else {
            toast.showMobileToast("Files saved in Downloads.");
            await OpenFile.open(filePath);
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      initDynamicLinks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final OTheme theme = locator<OTheme>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odin - Open-source easy file sharing for everyone.',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
