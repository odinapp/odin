part of '../home_page.dart';

class BGIllustration extends StatelessWidget {
  const BGIllustration({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Image.asset(
        oImage.odinBG,
        width: 492.toAutoScaledWidth,
        height: 474.toAutoScaledHeight,
      ),
    );
  }
}
