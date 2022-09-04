import 'package:odin/amenities/core/core_amenity.dart';
import 'package:odin/services/logger.dart';

class CoreAmenityImpl extends CoreAmenity {
  @override
  Future<void> bootUp() async {
    logger.d('[CoreAmenity.bootUp]');

    await Future.wait(
      CoreAmenity.amenities.map((amenity) {
        return amenity.bootUp().then((data) => amenity.onBootUp(data));
      }),
    );
  }

  @override
  void onBootUp(void data) {
    // Do nothing
    logger.d('[CoreAmenity.onBootUp]');
  }

  @override
  void bootDown() {
    logger.d('[CoreAmenity.bootDown]');
    for (var amenity in CoreAmenity.amenities.reversed) {
      amenity.bootDown();
    }
  }
}
