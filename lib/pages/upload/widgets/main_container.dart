part of '../view.dart';

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
        height: 688.toAutoScaledHeight,
        decoration: BoxDecoration(
          color: color.cardOnBackground,
          borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4.toAutoScaledHeight,
              left: 19.toAutoScaledWidth,
              child: TextButton(
                onPressed: () => locator<AppRouter>().pop(),
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      oImage.arrowLeft,
                      width: 16.toAutoScaledWidth,
                      height: 16.toAutoScaledHeight,
                    ),
                    16.toAutoScaledWidth.toHorizontalSizedBox,
                    Text(
                      'Back',
                      style: color.textStyle(
                        color: color.secondaryOnBackground,
                        fontSize: 24.toAutoScaledFont,
                        fontWeight: FontWeight.w300,
                        height: 28.toAutoScaledFont / 24.toAutoScaledFont,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
                child: Container(
                  width: 780.toAutoScaledWidth,
                  height: 96.toAutoScaledHeight,
                  // Todo:// Add color
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 100,
                      ),
                      height: 96.toAutoScaledHeight,
                      width: (Provider.of<DioNotifier>(context).progress * 780).toAutoScaledWidth,
                      decoration: BoxDecoration(
                        color: color.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
