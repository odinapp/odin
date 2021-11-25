import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class WindowButtons extends StatefulWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  final GlobalKey _menuKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: buttonColors,
          animate: true,
        ),
        Theme(
          data: ThemeData.dark(),
          child: PopupMenuButton(
              key: _menuKey,
              child: MenuWindowButton(
                colors: buttonColors,
                animate: true,
                onPressed: () {
                  dynamic state = _menuKey.currentState;
                  state.showButtonMenu();
                },
              ),
              itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text(
                        "About",
                        style: GoogleFonts.poppins(),
                      ),
                      value: 1,
                    ),
                    PopupMenuItem(
                      child: Text(
                        "Support",
                        style: GoogleFonts.poppins(),
                      ),
                      value: 2,
                    )
                  ]),
        ),
        CloseWindowButton(
          colors: closeButtonColors,
          animate: true,
        ),
      ],
    );
  }
}
