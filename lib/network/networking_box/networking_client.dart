part of 'networking_box.dart';

abstract class _ONetworkHeaderKeys {
  static const String contentType = 'Content-Type';
  static const String appVersion = 'X-App-Version';
  static const String deviceOs = 'X-Device-OS';
  static const String deviceOsVersion = 'X-Device-OS-Version';

  @Deprecated('Although can be used currently, it will be removed soon. Use appVersion instead.')
  static const String httpAppVersion = 'HTTP_X_APP_VERSION';

  @Deprecated('Although can be used currently, it will be removed soon. Use deviceOs instead.')
  static const String httpDeviceOs = 'HTTP_X_DEVICE_OS';

  @Deprecated('Although can be used currently, it will be removed soon. User deviceOsVersion instead.')
  static const String httpDeviceOsVersion = 'HTTP_X_DEVICE_OS_VERSION';

  @Deprecated('Although can be used currently, it will be removed soon. Don\'t have to send this in future.')
  static const String clientSecret = 'Client-Secret';

  @Deprecated('Although can be used currently, it will be removed soon. Don\'t have to send this in future.')
  static const String clientId = 'Client-Id';
}

class ONetworkingClient extends DioForNative {
  static final envService = locator<EnvironmentService>();
  // TODO: Add default base url for production
  static final String _baseUrl = '${envService.environment.API_URL}api/${envService.environment.API_VERSION}';

  // TODO: Add default required headers here
  static final Map<String, String> _defaultHeaders = {
    _ONetworkHeaderKeys.contentType: 'application/json',

    // TODO: Use AppInfoAmenity.instance.version instead
    _ONetworkHeaderKeys.appVersion: AppInfoAmenity.instance.info.version,
    _ONetworkHeaderKeys.httpAppVersion: AppInfoAmenity.instance.info.version,

    _ONetworkHeaderKeys.deviceOs: DeviceInfoAmenity.instance.info.osName,
    _ONetworkHeaderKeys.httpDeviceOs: DeviceInfoAmenity.instance.info.osName,

    _ONetworkHeaderKeys.deviceOsVersion: DeviceInfoAmenity.instance.info.osVersion,
    _ONetworkHeaderKeys.httpDeviceOsVersion: DeviceInfoAmenity.instance.info.osVersion,
  };

  ONetworkingClient({
    String? authorizationToken,
    String? timezone,
  }) : super(
          BaseOptions(
            baseUrl: _baseUrl,
            headers: {
              ..._defaultHeaders,
              if (authorizationToken != null) ...{'Authorization': 'Bearer $authorizationToken'},
              if (timezone != null) ...{'Timezone': timezone},
            },
            validateStatus: (_) => true,
          ),
        ) {
    logger.d('Headers : $_defaultHeaders');
  }

  ONetworkingClient.fromOptions(
    ONetworkingOptions options, {
    String? authorizationToken,
    String? timezone,
  }) : super(
          BaseOptions(
            baseUrl: options.baseUrl ?? _baseUrl,
            headers: {
              ..._defaultHeaders,
              if (options.headers != null) ...options.headers!,
              if (authorizationToken != null) ...{'Authorization': 'Bearer $authorizationToken'},
              if (timezone != null) ...{'Timezone': timezone},
            },
            responseType: options.responseType ?? ResponseType.json,
            validateStatus: (_) => true,
          ),
        );

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final response = await super.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    stopwatch.stop();
    logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
    return response;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final response = await super.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    stopwatch.stop();
    logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
    return response;
  }
}
