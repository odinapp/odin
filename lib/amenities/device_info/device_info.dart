import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:odin/amenities/device_info/amenity.dart';
import 'package:odin/services/logger.dart';

class DeviceInfoAmenityImpl implements DeviceInfoAmenity {
  @override
  late final ODeviceInfo info;

  @override
  Future<void> bootUp() async {
    logger.d('[DeviceInfo.bootUp]');

    final deviceInfo = DeviceInfoPlugin();

    if (!kIsWeb) {
      switch (Platform.operatingSystem) {
        case 'android':
          final aInfo = await deviceInfo.androidInfo;
          info = ODeviceInfo(
            osName: 'Android',
            osVersion: aInfo.version.release.toString(),
            deviceName: aInfo.model.toString(),
            deviceId: aInfo.id.toString(),
          );
          break;
        case 'ios':
          final iInfo = await deviceInfo.iosInfo;
          info = ODeviceInfo(
            osName: 'iOS',
            osVersion: iInfo.systemVersion.toString(),
            deviceName: iInfo.name.toString(),
            deviceId: iInfo.identifierForVendor.toString(),
          );
          break;
        case 'macos':
          final mInfo = await deviceInfo.macOsInfo;
          info = ODeviceInfo(
            osName: 'macOS',
            osVersion: mInfo.osRelease.toString(),
            deviceName: mInfo.model.toString(),
            deviceId: mInfo.systemGUID.toString(),
          );
          break;
        case 'windows':
          final wInfo = await deviceInfo.windowsInfo;
          info = ODeviceInfo(
            osName: 'Windows',
            osVersion: 'NA',
            deviceName: wInfo.computerName.toString(),
            deviceId: 'NA',
          );
          break;
        case 'linux':
          final lInfo = await deviceInfo.linuxInfo;
          info = ODeviceInfo(
            osName: 'Linux',
            osVersion: lInfo.version.toString(),
            deviceName: lInfo.name.toString(),
            deviceId: lInfo.id.toString(),
          );
          break;
        default:
          info = ODeviceInfo(
            osName: 'Unknown-Platform',
            osVersion: 'Unknown-Platform',
            deviceName: 'Unknown-Platform',
            deviceId: 'Unknown-Platform',
          );
      }
    } else {
      final webInfo = await deviceInfo.webBrowserInfo;
      info = ODeviceInfo(
        osName: 'Web',
        osVersion: webInfo.userAgent.toString(),
        deviceName: webInfo.browserName.toString(),
        deviceId: webInfo.appVersion.toString(),
      );
    }

    logger.d('DeviceInfo: $info');
  }

  @override
  void onBootUp(void data) {
    // Do nothing
    logger.d('[DeviceInfo.onBootUp]');
  }

  @override
  void bootDown() {
    // Do nothing
    logger.d('[DeviceInfo.bootDown]');
  }
}
