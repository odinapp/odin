import 'package:flutter/material.dart';

class TooltipCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = Colors.white.withOpacity(1.0);
    canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width, size.height * 0.8833333),
            bottomRight: Radius.circular(size.width * 0.05031447),
            bottomLeft: Radius.circular(size.width * 0.05031447),
            topLeft: Radius.circular(size.width * 0.05031447),
            topRight: Radius.circular(size.width * 0.05031447)),
        paint0Fill);

    Path path_1 = Path();
    path_1.moveTo(size.width * 0.5000000, size.height);
    path_1.lineTo(size.width * 0.4409937, size.height * 0.5937500);
    path_1.lineTo(size.width * 0.5590063, size.height * 0.5937500);
    path_1.lineTo(size.width * 0.5000000, size.height);
    path_1.close();

    Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = Colors.white.withOpacity(1.0);
    canvas.drawPath(path_1, paint1Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
