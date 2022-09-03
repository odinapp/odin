import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class MenuWindowButton extends WindowButton {
  MenuWindowButton({Key? key, WindowButtonColors? colors, VoidCallback? onPressed, bool? animate})
      : super(
            key: key,
            colors: colors,
            animate: animate ?? false,
            iconBuilder: (buttonContext) => MenuIcon(color: buttonContext.iconColor),
            onPressed: onPressed);
}

abstract class _IconPainter extends CustomPainter {
  _IconPainter(this.color);
  final Color color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
  const _AlignedPaint(this.painter, {Key? key}) : super(key: key);
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.center, child: CustomPaint(size: const Size(10, 30), painter: painter));
  }
}

class MenuIcon extends StatelessWidget {
  final Color color;
  const MenuIcon({Key? key, required this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) => _AlignedPaint(_MenuPainter(color));
}

class _MenuPainter extends _IconPainter {
  _MenuPainter(Color color) : super(color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawLine(Offset(0, size.height * 3 / 4), Offset(size.width, size.height * 3 / 4), p);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    canvas.drawLine(Offset(0, size.height / 4), Offset(size.width, size.height / 4), p);
  }
}
