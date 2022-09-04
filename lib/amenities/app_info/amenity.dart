import 'package:odin/amenities/amenity.dart';
import 'package:odin/amenities/app_info/app_info.dart';

class OAppInfo {
  final String name;
  final String version;
  final String buildNumber;

  OAppInfo({
    required this.name,
    required this.version,
    required this.buildNumber,
  });

  @override
  String toString() {
    return {
      'name': name,
      'version': version,
      'buildNumber': buildNumber,
    }.toString();
  }
}

abstract class AppInfoAmenity extends Amenity<void> {
  AppInfoAmenity._();

  // TODO: Use dependency injection instead
  static final AppInfoAmenity instance = AppInfoAmenityImpl();

  OAppInfo get info;
}
