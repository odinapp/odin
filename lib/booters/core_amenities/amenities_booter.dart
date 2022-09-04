import 'package:odin/amenities/core/core_amenity.dart';
import 'package:odin/booters/booter.dart';
import 'package:odin/services/logger.dart';

class AmenitiesBooter implements Booter<void> {
  static AmenitiesBooter instance = AmenitiesBooter._();

  AmenitiesBooter._();

  @override
  Future<void> bootUp() async {
    logger.d('AmenitiesBooter.bootUp');

    await CoreAmenity.instance.bootUp();
  }

  @override
  void bootDown() async {
    CoreAmenity.instance.bootDown();
  }
}
