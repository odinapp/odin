part of '../view.dart';

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 60.0.toAutoScaledWidth),
      child: Stack(
        children: [
          _ProgressBarBG(color: color),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [_FileIcon(color: color), _FileDataText(color: color)],
          ),
        ],
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 20.toAutoScaledHeight,
        horizontal: 16.0.toAutoScaledWidth,
      ),
      child: Container(
        width: 56.toAutoScaledWidth,
        height: 56.toAutoScaledHeight,
        decoration: BoxDecoration(
          // Todo:// Add color
          color: const Color(0xFFFFFFFF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.toAutoScaledWidth),
        ),
        child: Center(
          child: Text(
            Provider.of<DioNotifier>(context).selectedFiles.isNotEmpty
                ? Provider.of<DioNotifier>(context).selectedFiles.first.path.split('/').last[0].toUpperCase()
                : '\$',
            style: color.textStyle(
              color: color.secondaryOnBackground,
              fontSize: 28.toAutoScaledFont,
              fontWeight: FontWeight.w900,
              height: 30.toAutoScaledFont / 28.toAutoScaledFont,
            ),
          ),
        ),
      ),
    );
  }
}

class _FileDataText extends StatelessWidget {
  const _FileDataText({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FileNameText(color: color),
        6.toAutoScaledHeight.toVerticalSizedBox,
        _FileSizeText(color: color),
      ],
    );
  }
}

class _FileSizeText extends StatelessWidget {
  const _FileSizeText({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Text(
      Provider.of<DioNotifier>(context).selectedFiles.isNotEmpty
          ? formatBytes(Provider.of<DioNotifier>(context).selectedFilesSize, 0)
          : '0 MB',
      style: color.textStyle(
        color: color.secondaryOnBackground,
        fontSize: 18.toAutoScaledFont,
        fontWeight: FontWeight.w500,
        height: 22.toAutoScaledFont / 18.toAutoScaledFont,
      ),
    );
  }
}

class _FileNameText extends StatelessWidget {
  const _FileNameText({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Text(
      Provider.of<DioNotifier>(context).selectedFiles.isNotEmpty
          ? Provider.of<DioNotifier>(context).selectedFiles.length == 1
              ? Provider.of<DioNotifier>(context).selectedFiles.first.path.split('/').last
              : '${Provider.of<DioNotifier>(context).selectedFiles.first.path.split('/').last} + ${Provider.of<DioNotifier>(context).selectedFiles.length - 1} more'
          : 'File name does not exists.',
      style: color.textStyle(
        color: color.secondaryOnBackground,
        fontSize: 18.toAutoScaledFont,
        fontWeight: FontWeight.w500,
        height: 22.toAutoScaledFont / 18.toAutoScaledFont,
      ),
    );
  }
}

class _ProgressBarBG extends StatelessWidget {
  const _ProgressBarBG({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
      child: Container(
        width: 780.toAutoScaledWidth,
        height: 96.toAutoScaledHeight,
        decoration: BoxDecoration(
          // Todo:// Add color
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 100,
            ),
            height: 96.toAutoScaledHeight,
            width: (Provider.of<DioNotifier>(context).progress * 780).toAutoScaledWidth,
            decoration: BoxDecoration(
              color: color.primary.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }
}
