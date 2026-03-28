part of '../home_page.dart';

class BGIllustration extends StatelessWidget {
  const BGIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: ExcludeSemantics(
        child: Image.asset(
          oImage.odinBG,
          width: 492.toAutoScaledWidth,
          height: 474.toAutoScaledHeight,
        ),
      ),
    );
  }
}
