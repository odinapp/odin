// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [DownloadPage]
class DownloadRoute extends PageRouteInfo<void> {
  const DownloadRoute({List<PageRouteInfo>? children})
    : super(DownloadRoute.name, initialChildren: children);

  static const String name = 'DownloadRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DownloadPage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [UploadPage]
class UploadRoute extends PageRouteInfo<UploadRouteArgs> {
  UploadRoute({
    Key? key,
    required List<File> uploadFiles,
    List<PageRouteInfo>? children,
  }) : super(
         UploadRoute.name,
         args: UploadRouteArgs(key: key, uploadFiles: uploadFiles),
         initialChildren: children,
       );

  static const String name = 'UploadRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UploadRouteArgs>();
      return UploadPage(key: args.key, uploadFiles: args.uploadFiles);
    },
  );
}

class UploadRouteArgs {
  const UploadRouteArgs({this.key, required this.uploadFiles});

  final Key? key;

  final List<File> uploadFiles;

  @override
  String toString() {
    return 'UploadRouteArgs{key: $key, uploadFiles: $uploadFiles}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UploadRouteArgs) return false;
    return key == other.key &&
        const ListEquality<File>().equals(uploadFiles, other.uploadFiles);
  }

  @override
  int get hashCode =>
      key.hashCode ^ const ListEquality<File>().hash(uploadFiles);
}
