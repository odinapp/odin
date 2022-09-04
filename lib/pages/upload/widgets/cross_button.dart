part of '../view.dart';

class _CrossButton extends StatelessWidget {
  const _CrossButton({
    Key? key,
  }) : super(key: key);

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
            foregroundColor: Colors.red.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
            ),
            fixedSize: Size(96.toAutoScaledWidth, 96.toAutoScaledHeight),
          ),
        ),
        onPressed: () => locator<DioNotifier>().cancelCurrentRequest(),
        child: SvgPicture.asset(
          oImage.cross,
        ),
      ),
    );
  }
}
