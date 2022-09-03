part of '../home_page.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 52.toAutoScaledHeight, 0, 0),
      child: SizedBox(
        width: 300.toAutoScaledWidth,
        height: 96.toAutoScaledHeight,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: color.secondaryContainerOnBackground,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Recieve files',
                style: color.textStyle(
                  color: color.secondaryOnBackground,
                  fontSize: 28.toAutoScaledFont,
                  fontWeight: FontWeight.w800,
                  height: 34.toAutoScaledFont / 28.toAutoScaledFont,
                ),
              ),
              SvgPicture.asset(
                oImage.cloudDownload,
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
