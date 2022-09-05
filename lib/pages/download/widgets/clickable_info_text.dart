part of '../view.dart';

class _ClickableInfoText extends StatelessWidget {
  const _ClickableInfoText({
    Key? key,
    required this.color,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  final OColor color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(60.toAutoScaledWidth, 0.toAutoScaledHeight, 60.toAutoScaledWidth, 24.toAutoScaledHeight),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: color.textStyle(
                color: color.secondaryOnBackground,
                fontSize: 22.toAutoScaledFont,
                fontWeight: FontWeight.w300,
                height: 34.toAutoScaledFont / 22.toAutoScaledFont,
              ),
            ),
            TextSpan(
              text: 'Why?',
              recognizer: TapGestureRecognizer()..onTap = () {},
              style: color
                  .textStyle(
                    color: color.secondaryOnBackground,
                    fontSize: 22.toAutoScaledFont,
                    fontWeight: FontWeight.w300,
                    height: 34.toAutoScaledFont / 22.toAutoScaledFont,
                  )
                  .copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
