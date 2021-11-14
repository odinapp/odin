import 'package:flutter/material.dart';

class OdinLogoCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = Colors.white.withOpacity(1.0);
    canvas.drawCircle(Offset(size.width * 0.5000000, size.height * 0.5000000),
        size.width * 0.4986500, paint0Fill);

    Path path_1 = Path();
    path_1.moveTo(size.width * 0.2365020, size.height * 0.3188660);
    path_1.lineTo(size.width * 0.3739300, size.height * 0.3556900);
    path_1.lineTo(size.width * 0.4533800, size.height * 0.4351400);
    path_1.lineTo(size.width * 0.4992533, size.height * 0.3892700);
    path_1.lineTo(size.width * 0.5451267, size.height * 0.4351467);
    path_1.lineTo(size.width * 0.6245867, size.height * 0.3556867);
    path_1.lineTo(size.width * 0.7620033, size.height * 0.3188660);
    path_1.cubicTo(
        size.width * 0.7712500,
        size.height * 0.3533700,
        size.width * 0.7736100,
        size.height * 0.3893600,
        size.width * 0.7689467,
        size.height * 0.4247767);
    path_1.cubicTo(
        size.width * 0.7642833,
        size.height * 0.4601933,
        size.width * 0.7526900,
        size.height * 0.4943433,
        size.width * 0.7348300,
        size.height * 0.5252800);
    path_1.cubicTo(
        size.width * 0.7225500,
        size.height * 0.5465500,
        size.width * 0.7074733,
        size.height * 0.5660100,
        size.width * 0.6900400,
        size.height * 0.5831667);
    path_1.cubicTo(
        size.width * 0.6821167,
        size.height * 0.5909633,
        size.width * 0.6737033,
        size.height * 0.5982833,
        size.width * 0.6648500,
        size.height * 0.6050767);
    path_1.cubicTo(
        size.width * 0.6515800,
        size.height * 0.6152600,
        size.width * 0.6374333,
        size.height * 0.6241700,
        size.width * 0.6225967,
        size.height * 0.6317200);
    path_1.lineTo(size.width * 0.6690633, size.height * 0.6781867);
    path_1.cubicTo(
        size.width * 0.6467633,
        size.height * 0.7004867,
        size.width * 0.6202900,
        size.height * 0.7181767,
        size.width * 0.5911533,
        size.height * 0.7302467);
    path_1.cubicTo(
        size.width * 0.5620167,
        size.height * 0.7423133,
        size.width * 0.5307900,
        size.height * 0.7485267,
        size.width * 0.4992533,
        size.height * 0.7485267);
    path_1.cubicTo(
        size.width * 0.4677167,
        size.height * 0.7485267,
        size.width * 0.4364867,
        size.height * 0.7423133,
        size.width * 0.4073533,
        size.height * 0.7302467);
    path_1.cubicTo(
        size.width * 0.3782167,
        size.height * 0.7181767,
        size.width * 0.3517433,
        size.height * 0.7004867,
        size.width * 0.3294420,
        size.height * 0.6781867);
    path_1.lineTo(size.width * 0.3759100, size.height * 0.6317200);
    path_1.cubicTo(
        size.width * 0.3610733,
        size.height * 0.6241700,
        size.width * 0.3469267,
        size.height * 0.6152600,
        size.width * 0.3336567,
        size.height * 0.6050767);
    path_1.cubicTo(
        size.width * 0.3283440,
        size.height * 0.6010000,
        size.width * 0.3231907,
        size.height * 0.5967333,
        size.width * 0.3182063,
        size.height * 0.5922900);
    path_1.cubicTo(
        size.width * 0.3144977,
        size.height * 0.5889833,
        size.width * 0.3108823,
        size.height * 0.5855767,
        size.width * 0.3073647,
        size.height * 0.5820733);
    path_1.cubicTo(
        size.width * 0.3072117,
        size.height * 0.5819233,
        size.width * 0.3070583,
        size.height * 0.5817700,
        size.width * 0.3069057,
        size.height * 0.5816167);
    path_1.cubicTo(
        size.width * 0.2901323,
        size.height * 0.5648433,
        size.width * 0.2755883,
        size.height * 0.5459100,
        size.width * 0.2636770,
        size.height * 0.5252800);
    path_1.cubicTo(
        size.width * 0.2458157,
        size.height * 0.4943433,
        size.width * 0.2342230,
        size.height * 0.4601933,
        size.width * 0.2295603,
        size.height * 0.4247767);
    path_1.cubicTo(
        size.width * 0.2248977,
        size.height * 0.3893600,
        size.width * 0.2272563,
        size.height * 0.3533700,
        size.width * 0.2365020,
        size.height * 0.3188660);
    path_1.close();

    Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = Color(0xff7D5DEB).withOpacity(1.0);
    canvas.drawPath(path_1, paint1Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
