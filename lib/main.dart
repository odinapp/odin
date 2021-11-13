import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odin/pages/home_page.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await setupLocator();
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: const Color(0xCC222222),
  );
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (obj, stacktrace) {
    logger.e(obj, obj, stacktrace);
  });
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(412, 192);
    win.minSize = initialSize;
    win.size = initialSize;
    win.maxSize = initialSize;
    win.alignment = Alignment.center;
    win.title = "Odin";
    win.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odin',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
