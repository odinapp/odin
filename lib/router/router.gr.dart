// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

part of 'router.dart';

class _$AppRouter extends RootStackRouter {
  _$AppRouter([GlobalKey<NavigatorState>? navigatorKey]) : super(navigatorKey);

  @override
  final Map<String, PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return AdaptivePage<dynamic>(
          routeData: routeData, child: const HomePage());
    },
    UploadRoute.name: (routeData) {
      final args = routeData.argsAs<UploadRouteArgs>();
      return AdaptivePage<dynamic>(
          routeData: routeData,
          child: UploadPage(key: args.key, uploadFiles: args.uploadFiles));
    },
    DownloadRoute.name: (routeData) {
      return AdaptivePage<dynamic>(
          routeData: routeData, child: const DownloadPage());
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig('/home-page#redirect',
            path: '/home-page', redirectTo: '/', fullMatch: true),
        RouteConfig(HomeRoute.name, path: '/'),
        RouteConfig(UploadRoute.name, path: '/upload'),
        RouteConfig(DownloadRoute.name, path: '/download')
      ];
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute() : super(HomeRoute.name, path: '/');

  static const String name = 'HomeRoute';
}

/// generated route for
/// [UploadPage]
class UploadRoute extends PageRouteInfo<UploadRouteArgs> {
  UploadRoute({Key? key, required List<File> uploadFiles})
      : super(UploadRoute.name,
            path: '/upload',
            args: UploadRouteArgs(key: key, uploadFiles: uploadFiles));

  static const String name = 'UploadRoute';
}

class UploadRouteArgs {
  const UploadRouteArgs({this.key, required this.uploadFiles});

  final Key? key;

  final List<File> uploadFiles;

  @override
  String toString() {
    return 'UploadRouteArgs{key: $key, uploadFiles: $uploadFiles}';
  }
}

/// generated route for
/// [DownloadPage]
class DownloadRoute extends PageRouteInfo<void> {
  const DownloadRoute() : super(DownloadRoute.name, path: '/download');

  static const String name = 'DownloadRoute';
}
