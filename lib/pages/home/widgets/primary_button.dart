part of '../home_page.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        60.toAutoScaledWidth,
        0,
        0,
        60.toAutoScaledHeight,
      ),
      child: SizedBox(
        width: 276.toAutoScaledWidth,
        height: 96.toAutoScaledHeight,
        child: ElevatedButton(
          onPressed: () async {
            final pick = await locator<FileService>().pickMultipleFiles();
            if (!context.mounted) return;
            if (pick.errorMessage != null) {
              showOdinHomeSnackBar(context, pick.errorMessage!);
              return;
            }
            final files = pick.files;
            if (files != null) {
              locator<AppRouter>().push(UploadRoute(uploadFiles: files));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color.secondary,
            foregroundColor: color.primary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.toAutoScaledWidth),
            ),
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.hovered)) {
                return color.primary.withValues(alpha: 0.07);
              }
              if (states.contains(MaterialState.focused)) {
                return color.primary.withValues(alpha: 0.12);
              }
              if (states.contains(MaterialState.pressed)) {
                return color.primary.withValues(alpha: 0.14);
              }
              return null;
            }),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  oApp.currentConfig?.home.primaryButtonText ?? 'Send files',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: color.textStyle(
                    color: color.primary,
                    fontSize: 28.toAutoScaledFont,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(width: 8.toAutoScaledWidth),
              SvgPicture.asset(
                oImage.arrowRight,
                width: 28.toAutoScaledWidth,
                height: 28.toAutoScaledHeight,
                colorFilter: ColorFilter.mode(
                  color.primary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
