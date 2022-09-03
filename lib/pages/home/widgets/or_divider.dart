part of '../home_page.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      oImage.orDivider,
      width: 258.toAutoScaledWidth,
      height: 22.toAutoScaledHeight,
    );
  }
}
