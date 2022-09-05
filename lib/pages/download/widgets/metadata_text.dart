part of '../view.dart';

class _MetadataText extends StatelessWidget {
  const _MetadataText({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0.toAutoScaledHeight, horizontal: 64.0.toAutoScaledWidth),
      child: SizedBox(
        height: 24.toAutoScaledHeight,
        width: double.maxFinite,
        child: Text(
          Provider.of<DioNotifier>(context).miniApiStatus == ApiStatus.failed
              ? Provider.of<DioNotifier>(context).fetchFilesMetadataFailure?.message ?? 'Invalid token'
              : Provider.of<DioNotifier>(context).miniApiStatus == ApiStatus.success
                  ? Provider.of<DioNotifier>(context).fetchFilesMetadataSuccess?.filesMetadata.basePath ??
                      'No base path'
                  : '',
          style: TextStyle(
            color: color.secondaryOnBackground,
            fontSize: 18.toAutoScaledFont,
            fontWeight: FontWeight.w300,
            height: 24.toAutoScaledFont / 18.toAutoScaledFont,
          ),
        ),
      ),
    );
  }
}
