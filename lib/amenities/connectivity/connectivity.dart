import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:odin/amenities/connectivity/amenity.dart';
import 'package:odin/services/logger.dart';

class ConnectivityAmenityImpl implements ConnectivityAmenity {
  final StreamController<ConnectivityStatus> _connectivityStatusStreamController =
      StreamController<ConnectivityStatus>.broadcast();

  late StreamSubscription<ConnectivityResult> _connectivityResultStreamSubscription;

  @override
  Stream<ConnectivityStatus> get onConnectivityStatusChanged => _connectivityStatusStreamController.stream;

  @override
  Future<ConnectivityStatus> get currentConnectivityStatus async {
    var connectivityStatus = ConnectivityStatus.connected;

    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      connectivityStatus = ConnectivityStatus.disconnected;
    }

    return connectivityStatus;
  }

  @override
  Future<void> bootUp() async {
    logger.d('[Connectivity.bootUp]');

    final connectivity = Connectivity();
    _connectivityResultStreamSubscription = connectivity.onConnectivityChanged.listen(
      (connectivityResult) {
        if (connectivityResult == ConnectivityResult.none) {
          logger.d('[connectivity.onConnectivityChanged] disconnected');
          _connectivityStatusStreamController.add(ConnectivityStatus.disconnected);
        } else {
          logger.d('[connectivity.onConnectivityChanged] connected');
          _connectivityStatusStreamController.add(ConnectivityStatus.connected);
        }
      },
    );
  }

  @override
  void onBootUp(void data) {
    // Do nothing
    logger.d('[Connectivity.onBootUp]');
  }

  @override
  void bootDown() {
    logger.d('[Connectivity.bootDown]');
    _connectivityResultStreamSubscription.cancel();
    _connectivityStatusStreamController.close();
  }
}
