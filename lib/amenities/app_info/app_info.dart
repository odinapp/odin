import 'package:odin/amenities/app_info/amenity.dart';
import 'package:odin/services/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoAmenityImpl implements AppInfoAmenity {
  @override
  late final OAppInfo info;

  @override
  Future<void> bootUp() async {
    logger.d('[AppInfo.bootUp]');

    final packageInfo = await PackageInfo.fromPlatform();

    info = OAppInfo(
      name: packageInfo.appName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );

    logger.d('AppInfo $info');
  }

  @override
  void onBootUp(void data) {
    // Do nothing
    logger.d('[AppInfo.onBootUp]');
  }

  @override
  void bootDown() {
    // Do nothing
    logger.d('[AppInfo.bootDown]');
  }
}
