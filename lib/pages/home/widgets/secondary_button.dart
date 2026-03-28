part of '../home_page.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 52.toAutoScaledHeight, 0, 0),
      child: SizedBox(
        width: 300.toAutoScaledWidth,
        height: 96.toAutoScaledHeight,
        child: ElevatedButton(
          onPressed: () {
            locator<AppRouter>().push(const DownloadRoute());
          },
          style:
              ElevatedButton.styleFrom(
                backgroundColor: color.cardOnBackground,
                foregroundColor: color.secondaryOnBackground,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.toAutoScaledWidth),
                  side: BorderSide(color: color.borderSubtleOnBackground),
                ),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.hovered)) {
                    return color.secondary.withValues(alpha: 0.06);
                  }
                  if (states.contains(MaterialState.focused)) {
                    return color.secondary.withValues(alpha: 0.1);
                  }
                  if (states.contains(MaterialState.pressed)) {
                    return color.secondary.withValues(alpha: 0.12);
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
                  oApp.currentConfig?.home.secondaryButtonText ??
                      'Receive files',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: color.textStyle(
                    color: color.secondaryOnBackground,
                    fontSize: 28.toAutoScaledFont,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(width: 8.toAutoScaledWidth),
              SvgPicture.asset(
                oImage.cloudDownload,
                width: 28.toAutoScaledWidth,
                height: 28.toAutoScaledHeight,
                colorFilter: ColorFilter.mode(
                  color.secondaryOnBackground,
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
