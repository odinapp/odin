part of '../view.dart';

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    Key? key,
    required this.color,
    required this.enabled,
    required this.onPressed,
  }) : super(key: key);

  final OColor color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.toAutoScaledWidth,
      height: 96.toAutoScaledHeight,
      child: ElevatedButton(
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
          ).merge(
            ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
              ),
              fixedSize: Size(96.toAutoScaledWidth, 96.toAutoScaledHeight),
            ),
          ),
          statesController: MaterialStatesController(),
          onPressed: enabled ? onPressed : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Receive files',
                style: color.textStyle(
                  color: color.secondary,
                  fontSize: 28.toAutoScaledFont,
                  fontWeight: FontWeight.w800,
                  height: 34.toAutoScaledFont / 28.toAutoScaledFont,
                ),
              ),
              SvgPicture.asset(
                oImage.cloudDownload,
                color: color.secondary,
                width: 28.toAutoScaledWidth,
                height: 28.toAutoScaledHeight,
              ),
            ],
          )),
    );
  }
}
