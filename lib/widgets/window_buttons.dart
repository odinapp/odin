import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:odin/widgets/menu_window_button.dart';

final buttonColors = WindowButtonColors(
  iconNormal: const Color(0x77FFFFFF),
  mouseOver: const Color(0x11FFFFFF),
  mouseDown: const Color(0x44FFFFFF),
  iconMouseOver: const Color(0xEEFFFFFF),
  iconMouseDown: const Color(0xFFFFFFFF),
);

final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0x11FFFFFF),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0x77FFFFFF),
    iconMouseOver: const Color(0xFFD32F2F));

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: buttonColors,
          animate: true,
        ),
        MenuWindowButton(
          colors: buttonColors,
          animate: true,
        ),
        CloseWindowButton(
          colors: closeButtonColors,
          animate: true,
        ),
      ],
    );
  }
}
