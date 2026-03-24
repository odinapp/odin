import 'dart:async';

import 'package:dio/dio.dart';
import 'package:odin/amenities/connectivity/amenity.dart';
import 'package:odin/network/networking_box/networking_box.dart';
import 'package:odin/services/logger.dart';

class ORetryInterceptor extends Interceptor {
  final ONetworkingClient client;

  late StreamSubscription<ConnectivityStatus> onConnectivityStatusChangedSubscription;

  bool isDisconnected = false;

  ORetryInterceptor({
    required this.client,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.isRetryRequired) {
      isDisconnected = true;

      onConnectivityStatusChangedSubscription = ConnectivityAmenity.instance.onConnectivityStatusChanged.listen(
        (connectivityStatus) async {
          if (connectivityStatus == ConnectivityStatus.connected) {
            onConnectivityStatusChangedSubscription.cancel();

            if (isDisconnected) {
              logger.d('[ORetryInterceptor.onError] retry initiated');
              isDisconnected = false;

              try {
                final retryResponse = await client.dio.fetch(err.requestOptions);
                handler.resolve(retryResponse);
              } catch (e) {
                if (e is DioException) {
                  handler.next(e);
                } else {
                  handler.next(
                    DioException(requestOptions: err.requestOptions, error: e),
                  );
                }
              }
            }
          }
        },
      );
    } else {
      handler.next(err);
    }
  }
}

extension on DioException {
  bool get isRetryRequired {
    return false;
  }
}
