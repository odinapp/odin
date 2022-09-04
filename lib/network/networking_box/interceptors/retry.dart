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
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.isRetryRequired) {
      isDisconnected = true;

      onConnectivityStatusChangedSubscription = ConnectivityAmenity.instance.onConnectivityStatusChanged.listen(
        (connectivityStatus) async {
          if (connectivityStatus == ConnectivityStatus.connected) {
            onConnectivityStatusChangedSubscription.cancel();

            if (isDisconnected) {
              logger.d('[ORetryInterceptor.onError] retry initiated');
              isDisconnected = false;

              final requestOptions = err.requestOptions;

              final retryResponse = await client.request(
                requestOptions.path,
                cancelToken: requestOptions.cancelToken,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                onSendProgress: requestOptions.onSendProgress,
                onReceiveProgress: requestOptions.onReceiveProgress,
              );

              handler.resolve(retryResponse);
            }
          }
        },
      );
    } else {
      super.onError(err, handler);
    }
  }
}

extension on DioError {
  bool get isRetryRequired {
    return false;
  }
}
