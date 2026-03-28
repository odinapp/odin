part of '../home_page.dart';

class MainContainer extends StatelessWidget {
  const MainContainer({super.key, required this.color});

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
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(right: 40.toAutoScaledWidth),
                      child: HeaderTitle(color: color),
                    ),
                  ),
                  PrimaryButton(color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
