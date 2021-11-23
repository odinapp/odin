import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/pages/home_page.dart';
import 'package:odin/providers/file_notifier.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:provider/provider.dart';

void main() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    TestWidgetsFlutterBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odin - Open Source easy file sharing for everyone.',
      theme: ThemeData(primarySwatch: Colors.deepPurple).copyWith(
          textTheme: TextTheme(
        headline1: GoogleFonts.poppins(
            fontSize: 93, fontWeight: FontWeight.w300, letterSpacing: -1.5),
        headline2: GoogleFonts.poppins(
            fontSize: 58, fontWeight: FontWeight.w300, letterSpacing: -0.5),
        headline3:
            GoogleFonts.poppins(fontSize: 46, fontWeight: FontWeight.w400),
        headline4: GoogleFonts.poppins(
            fontSize: 33, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        headline5:
            GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w400),
        headline6: GoogleFonts.poppins(
            fontSize: 19, fontWeight: FontWeight.w500, letterSpacing: 0.15),
        subtitle1: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.15),
        subtitle2: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyText1: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.5),
        bodyText2: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        button: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.25),
        caption: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        overline: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
      )),
      home: const HomePage(),
    );
  }
}
