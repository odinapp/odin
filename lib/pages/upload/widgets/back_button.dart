part of '../view.dart';

class _BackButton extends StatelessWidget {
  const _BackButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              oApp.currentConfig?.upload.backButtonText ?? 'Back',
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
    );
  }
}
