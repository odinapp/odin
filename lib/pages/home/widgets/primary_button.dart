part of '../home_page.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(60.toAutoScaledWidth, 0, 0, 60.toAutoScaledHeight),
      child: SizedBox(
        width: 276.toAutoScaledWidth,
        height: 96.toAutoScaledHeight,
        child: ElevatedButton(
          onPressed: () async {
            final dummyFiles = await locator<FileService>().pickMultipleFiles();
            if (dummyFiles != null) {
              locator<AppRouter>().push(
                UploadRoute(
                  uploadFiles: dummyFiles,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color.secondary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Send files',
                style: color.textStyle(
                  color: color.primary,
                  fontSize: 28.toAutoScaledFont,
                  fontWeight: FontWeight.w800,
                  height: 34.toAutoScaledFont / 28.toAutoScaledFont,
                ),
              ),
              SvgPicture.asset(
                oImage.arrowRight,
                width: 28.toAutoScaledWidth,
                height: 28.toAutoScaledHeight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
