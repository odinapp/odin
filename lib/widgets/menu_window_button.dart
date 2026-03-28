import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class MenuWindowButton extends WindowButton {
  MenuWindowButton({super.key, super.colors, super.onPressed, bool? animate})
    : super(
        animate: animate ?? false,
        iconBuilder: (buttonContext) =>
            MenuIcon(color: buttonContext.iconColor),
      );
}

abstract class _IconPainter extends CustomPainter {
  _IconPainter(this.color);
  final Color color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
  const _AlignedPaint(this.painter);
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: CustomPaint(size: const Size(10, 30), painter: painter),
    );
  }
}

class MenuIcon extends StatelessWidget {
  final Color color;
  const MenuIcon({super.key, required this.color});
  @override
  Widget build(BuildContext context) => _AlignedPaint(_MenuPainter(color));
}

class _MenuPainter extends _IconPainter {
  _MenuPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawLine(
      Offset(0, size.height * 3 / 4),
      Offset(size.width, size.height * 3 / 4),
      p,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      p,
    );
    canvas.drawLine(
      Offset(0, size.height / 4),
      Offset(size.width, size.height / 4),
      p,
    );
  }
}
