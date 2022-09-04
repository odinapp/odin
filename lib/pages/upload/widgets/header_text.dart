part of '../view.dart';

class _HeaderText extends StatelessWidget {
  const _HeaderText({
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
        'Uploading...',
        style: color.textStyle(
          color: color.secondary,
          fontSize: 48.toAutoScaledFont,
          fontWeight: FontWeight.w900,
          height: 58.toAutoScaledFont / 48.toAutoScaledFont,
        ),
      ),
    );
  }
}
