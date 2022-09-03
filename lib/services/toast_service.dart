import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class ToastService {
  late FToast fToast;

  void init(BuildContext context) {
    fToast = FToast();
    fToast.init(context);
  }

  void showToast(IconData icon, String text) {
    Widget toast = SizedBox(
        width: 250,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(500.0), color: Colors.black54),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 12.0,
                ),
                Text(
                  text,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ));
    fToast.removeCustomToast();
    if (Platform.isIOS || Platform.isAndroid) {
      Fluttertoast.showToast(
          msg: text,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      fToast.showToast(
        child: toast,
        positionedToastBuilder: (context, child) {
          return Positioned(
            top: 32.0 + MediaQuery.of(context).padding.top,
            left: MediaQuery.of(context).size.width / 2 - 125,
            child: child,
          );
        },
        toastDuration: const Duration(seconds: 2),
      );
    }
  }

  void showMobileToast(String text) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
