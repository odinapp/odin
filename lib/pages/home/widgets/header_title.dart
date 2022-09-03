part of '../home_page.dart';

class HeaderTitle extends StatelessWidget {
  const HeaderTitle({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(60.toAutoScaledWidth, 60.toAutoScaledHeight, 0, 0),
      child: Text(
        'Open-source\neasy file sharing\nfor everyone.',
        style: color.textStyle(
          color: color.secondary,
          fontSize: 68.toAutoScaledFont,
          fontWeight: FontWeight.w900,
          height: 82.toAutoScaledFont / 68.toAutoScaledFont,
        ),
      ),
    );
  }
}
