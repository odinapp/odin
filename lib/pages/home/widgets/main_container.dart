part of '../home_page.dart';

class MainContainer extends StatelessWidget {
  const MainContainer({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
      child: Container(
        width: 1040.toAutoScaledWidth,
        height: 512.toAutoScaledHeight,
        decoration: BoxDecoration(
          color: color.primary,
          borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
        ),
        child: Stack(
          children: [
            const BGIllustration(),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderTitle(color: color),
                PrimaryButton(color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
