import 'package:odin/amenities/amenity.dart';
import 'package:odin/amenities/device_info/device_info.dart';

class ODeviceInfo {
  final String osName;
  final String osVersion;
  final String deviceName;
  final String deviceId;

  ODeviceInfo({
    required this.osName,
    required this.osVersion,
    required this.deviceName,
    required this.deviceId,
  });

  @override
  String toString() {
    return {
      'osName': osName,
      'osVersion': osVersion,
      'deviceName': deviceName,
      'deviceId': deviceId,
    }.toString();
  }
}

abstract class DeviceInfoAmenity extends Amenity<void> {
  DeviceInfoAmenity._();

  // TODO: Use dependency injection instead
  static final DeviceInfoAmenity instance = DeviceInfoAmenityImpl();

  ODeviceInfo get info;
}
