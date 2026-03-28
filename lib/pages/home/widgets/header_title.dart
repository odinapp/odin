part of '../home_page.dart';

class HeaderTitle extends StatelessWidget {
  const HeaderTitle({super.key, required this.color});

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        60.toAutoScaledWidth,
        60.toAutoScaledHeight,
        0,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720.toAutoScaledWidth),
        child: Text(
          oApp.currentConfig?.home.title ??
              'Open-source\neasy file sharing\nfor everyone.',
          textAlign: TextAlign.start,
          softWrap: true,
          style: color.textStyle(
            color: color.secondary,
            fontSize: 68.toAutoScaledFont,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -1.2,
          ),
        ),
      ),
    );
  }
}
