part of '../view.dart';

class SuccessBody extends StatelessWidget {
  const SuccessBody({
    Key? key,
    required this.color,
    required this.fetchFilesMetadataSuccess,
  }) : super(key: key);

  final OColor color;
  final FetchFilesMetadataSuccess fetchFilesMetadataSuccess;

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
            _BackButton(color: color),
            _SuccessContent(color: color),
          ],
        ),
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                oImage.success,
                width: 264.toAutoScaledWidth,
                height: 264.toAutoScaledHeight,
              ),
            ),
            _InfoText(
              color: color,
              text: 'The files were successfully uploaded!\nPlease share the token below to access these files.',
              center: true,
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 519.toAutoScaledWidth,
              height: 96.toAutoScaledHeight,
              decoration: BoxDecoration(
                // Todo:// Add color
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 40.0.toAutoScaledWidth),
                      child: Text(
                        Provider.of<DioNotifier>(context).fetchFilesMetadataSuccess?.filesMetadata.basePath ??
                            'Cannot fetch token',
                        overflow: TextOverflow.ellipsis,
                        style: color.textStyle(
                          color: color.secondaryOnBackground,
                          fontSize: 28.toAutoScaledFont,
                          fontWeight: FontWeight.w700,
                          height: 34.toAutoScaledFont / 28.toAutoScaledFont,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: Provider.of<DioNotifier>(
                                context,
                                listen: false,
                              ).fetchFilesMetadataSuccess?.filesMetadata.basePath ??
                              'Cannot fetch token'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied to clipboard',
                            style: color.textStyle(
                              color: color.secondaryOnBackground,
                              fontSize: 28.toAutoScaledFont,
                              fontWeight: FontWeight.w700,
                              height: 34.toAutoScaledFont / 28.toAutoScaledFont,
                            ),
                          ),
                          backgroundColor: color.cardOnBackground,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
                          ),
                        ),
                      );
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                    child: SvgPicture.asset(
                      oImage.copy,
                      width: 34.toAutoScaledWidth,
                      height: 34.toAutoScaledHeight,
                    ),
                  )
                ],
              ),
            ),
            40.toAutoScaledWidth.toHorizontalSizedBox,
            _QRButton(color: color),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _QRButton extends StatelessWidget {
  const _QRButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 60.0.toAutoScaledWidth),
      child: ElevatedButton(
        style: ButtonStyle(
          elevation: MaterialStateProperty.all(0),
        ).merge(
          ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF242424),
            foregroundColor: color.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
            ),
            fixedSize: Size(96.toAutoScaledWidth, 96.toAutoScaledHeight),
          ),
        ),
        onPressed: () {},
        child: SvgPicture.asset(
          oImage.qr,
        ),
      ),
    );
  }
}
