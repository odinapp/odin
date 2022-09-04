import 'package:odin/amenities/amenity.dart';
import 'package:odin/amenities/connectivity/connectivity.dart';

enum ConnectivityStatus {
  connected,
  disconnected,
}

abstract class ConnectivityAmenity extends Amenity<void> {
  static final ConnectivityAmenity instance = ConnectivityAmenityImpl();

  Future<ConnectivityStatus> get currentConnectivityStatus;
  Stream<ConnectivityStatus> get onConnectivityStatusChanged;
}
