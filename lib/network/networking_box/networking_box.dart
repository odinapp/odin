import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:odin/network/networking_box/interceptors/retry.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';

import './interceptors/logging.dart';
import './interceptors/no_token.dart';

part './networking_client.dart';
part './networking_options.dart';

abstract class ONetworkingBox {
  ONetworkingBox._();

  /// Returns `null` if this client cannot be created
  static Future<ONetworkingClient?> unsecureClient({
    ONetworkingOptions? options,
    bool loggingEnabled = true,
  }) async {
    final client = await _createUnsecureClient(options: options);

    return client;
  }

  /// Returns `null` if this client cannot be created
  static Future<ONetworkingClient?> secureClient({
    ONetworkingOptions? options,
    bool loggingEnabled = true,
  }) async {
    ONetworkingClient? client;

    final isUserLoggedIn = false;
    logger.d('QBackgroundCaching isUserLoggedIn: $isUserLoggedIn');

    if (isUserLoggedIn) {
      logger.d('QBackgroundCaching secureClient from isUserLoggedIn: $isUserLoggedIn');
      client = await _createSecureClient(options: options);
    } else {
      logger.d('[secureClient] Client could not be created');
    }

    return client;
  }

  static Future<ONetworkingClient> _createUnsecureClient({
    ONetworkingOptions? options,
    bool loggingEnabled = true,
  }) async {
    final currentTimezoneRegion = await FlutterNativeTimezone.getLocalTimezone();

    final client = options != null
        ? ONetworkingClient.fromOptions(
            options,
            timezone: currentTimezoneRegion,
          )
        : ONetworkingClient(
            timezone: currentTimezoneRegion,
          );

    if (loggingEnabled) {
      client.addLoggingIntercept();
    }

    return client;
  }

  static Future<ONetworkingClient?> _createSecureClient({
    ONetworkingOptions? options,
    bool loggingEnabled = true,
  }) async {
    final currentTimezoneRegion = await FlutterNativeTimezone.getLocalTimezone();

    final token = 'ODIN_NO_TOKEN';

    logger.d('QBackgroundCaching inside secureClient token: $token');
    try {
      final client = options != null
          ? ONetworkingClient.fromOptions(
              options,
              authorizationToken: token,
              timezone: currentTimezoneRegion,
            )
          : ONetworkingClient(
              authorizationToken: token,
              timezone: currentTimezoneRegion,
            );

      if (loggingEnabled) {
        client.addLoggingIntercept();
      }
      return client;
    } catch (e, s) {
      logger.e('QBackgroundCaching error: $e \n QBackgroundCaching stacktrace: $s');
      return null;
    }
  }
}

extension on ONetworkingClient {
  void addLoggingIntercept() {
    interceptors.add(ORetryInterceptor(client: this));
    interceptors.add(ONetworkLoggingInterceptor());
    interceptors.add(OTokenInvalidInterceptor());
  }
}
