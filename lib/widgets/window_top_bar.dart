import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:odin/widgets/window_buttons.dart';

class WindowTopBar extends StatelessWidget {
  const WindowTopBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (Platform.isWindows || Platform.isMacOS)
        ? WindowTitleBarBox(
            child: Row(
              children: [
                Expanded(
                  child: MoveWindow(),
                ),
                const WindowButtons()
              ],
            ),
          )
        : Container();
  }
}
