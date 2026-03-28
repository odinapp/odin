part of '../view.dart';

class _InfoText extends StatelessWidget {
  const _InfoText({
    required this.color,
    required this.text,
    this.center = false,
  });

  final OColor color;
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        60.toAutoScaledWidth,
        0.toAutoScaledHeight,
        60.toAutoScaledWidth,
        24.toAutoScaledHeight,
      ),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: color.textStyle(
          color: color.secondaryOnBackground,
          fontSize: 22.toAutoScaledFont,
          fontWeight: FontWeight.w300,
          height: 34.toAutoScaledFont / 22.toAutoScaledFont,
        ),
      ),
    );
  }
}
