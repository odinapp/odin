import 'dart:math';

import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  const RipplePainter({
    required this.color,
    required this.animationValue,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = ((1 - animationValue)).clamp(0, 0.2);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        animationValue * size.height * 0.3,
        Paint()..color = color.withOpacity(pow(opacity, 2).toDouble()));
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        animationValue * size.height * 0.25,
        Paint()..color = color.withOpacity(pow(opacity, 1.5).toDouble()));
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        animationValue * size.height * 0.2,
        Paint()..color = color.withOpacity(opacity));
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(RipplePainter oldDelegate) => false;
}
