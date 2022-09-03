import 'package:flutter/material.dart';

class DropIconCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = Colors.white.withOpacity(1.0);
    canvas.drawCircle(Offset(size.width * 0.5000000, size.height * 0.5000000), size.width * 0.4986500, paint0Fill);

    Path path_1 = Path();
    path_1.moveTo(size.width * 0.5000000, size.height * 0.5000000);
    path_1.lineTo(size.width * 0.3333333, size.height * 0.5000000);
    path_1.moveTo(size.width * 0.5000000, size.height * 0.3333333);
    path_1.lineTo(size.width * 0.5000000, size.height * 0.5000000);
    path_1.lineTo(size.width * 0.5000000, size.height * 0.3333333);
    path_1.close();
    path_1.moveTo(size.width * 0.5000000, size.height * 0.5000000);
    path_1.lineTo(size.width * 0.5000000, size.height * 0.6666667);
    path_1.lineTo(size.width * 0.5000000, size.height * 0.5000000);
    path_1.close();
    path_1.moveTo(size.width * 0.5000000, size.height * 0.5000000);
    path_1.lineTo(size.width * 0.6666667, size.height * 0.5000000);
    path_1.lineTo(size.width * 0.5000000, size.height * 0.5000000);
    path_1.close();

    Paint paint1Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05555567;
    paint1Stroke.color = const Color(0xff7D5DEB).withOpacity(1.0);
    paint1Stroke.strokeCap = StrokeCap.round;
    paint1Stroke.strokeJoin = StrokeJoin.round;
    canvas.drawPath(path_1, paint1Stroke);

    Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = const Color(0xff000000).withOpacity(1.0);
    canvas.drawPath(path_1, paint1Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
