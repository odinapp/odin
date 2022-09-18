part of '../view.dart';

class MainContainer extends StatelessWidget {
  const MainContainer({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

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
            MainContent(color: color),
          ],
        ),
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  const MainContent({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderText(color: color),
            _InfoText(
              color: color,
              text: oApp.currentConfig?.upload.description ??
                  'The files are protected with end to end AES-256 encryption and can only be accessed using a unique token.',
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ProgressBar(color: color),
            const _CrossButton(),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}
