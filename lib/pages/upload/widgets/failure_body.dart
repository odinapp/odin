part of '../view.dart';

class FailedBody extends StatelessWidget {
  const FailedBody({
    Key? key,
    required this.color,
    required this.uploadFilesFailure,
  }) : super(key: key);

  final OColor color;
  final UploadFilesFailure uploadFilesFailure;

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
        child: _FailureContent(color: color),
      ),
    );
  }
}

class _FailureContent extends StatelessWidget {
  const _FailureContent({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 34.0.toAutoScaledHeight,
              ),
              child: Image.asset(
                oImage.faliure,
                width: 264.toAutoScaledWidth,
                height: 264.toAutoScaledHeight,
              ),
            ),
            _InfoText(
              color: color,
              text: Provider.of<DioNotifier>(context).uploadFilesFailure?.message ?? 'Oops! Something went wrong.',
              center: true,
            ),
          ],
        ),
        const Spacer(),
        Center(
          child: Container(
            width: 354.toAutoScaledWidth,
            height: 96.toAutoScaledHeight,
            decoration: BoxDecoration(
              // Todo:// Add color
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
            ),
            child: TextButton(
              onPressed: () => locator<AppRouter>().pop(),
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 40.0.toAutoScaledWidth),
                    child: SvgPicture.asset(
                      oImage.arrowLeft,
                      width: 16.toAutoScaledWidth,
                      height: 16.toAutoScaledHeight,
                    ),
                  ),
                  16.toAutoScaledWidth.toHorizontalSizedBox,
                  Padding(
                    padding: EdgeInsets.only(right: 40.0.toAutoScaledWidth),
                    child: Text(
                      'Back to home',
                      style: color.textStyle(
                        color: color.secondaryOnBackground,
                        fontSize: 28.toAutoScaledFont,
                        fontWeight: FontWeight.w800,
                        height: 34.toAutoScaledFont / 28.toAutoScaledFont,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
