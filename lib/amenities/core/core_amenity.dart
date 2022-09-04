import 'dart:collection';

import 'package:odin/amenities/amenity.dart';
import 'package:odin/amenities/app_info/amenity.dart';
import 'package:odin/amenities/auth/amenity.dart';
import 'package:odin/amenities/connectivity/amenity.dart';
import 'package:odin/amenities/core/core_amenity_impl.dart';
import 'package:odin/amenities/device_info/amenity.dart';

/// [CoreAmenity] is responsible for registering all the other amenities and handle their
/// bootUp and bootDown.
///
/// bootUps are evaluated in the order of occurrence in the [CoreAmenity.amenities] array.
/// bootDowns occur in reverse order of the same.
abstract class CoreAmenity implements Amenity<void> {
  // TODO: Use dependency injection instead
  static final CoreAmenity instance = CoreAmenityImpl();

  static final List<Amenity> amenities = UnmodifiableListView([
    ConnectivityAmenity.instance,
    AppInfoAmenity.instance,
    DeviceInfoAmenity.instance,
    AuthAmenity.instance,
  ]);
}
