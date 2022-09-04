part of '../view.dart';

class _InfoText extends StatelessWidget {
  const _InfoText({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(60.toAutoScaledWidth, 0.toAutoScaledHeight, 60.toAutoScaledWidth, 24.toAutoScaledHeight),
      child: Text(
        'The files are protected with end to end AES-256 encryption and can only be accessed using a unique token.',
        style: color.textStyle(
          color: color.secondaryOnBackground,
          fontSize: 24.toAutoScaledFont,
          fontWeight: FontWeight.w300,
          height: 36.toAutoScaledFont / 24.toAutoScaledFont,
        ),
      ),
    );
  }
}
