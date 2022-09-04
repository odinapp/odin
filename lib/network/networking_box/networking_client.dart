part of 'networking_box.dart';

abstract class _ONetworkHeaderKeys {
  static const String contentType = 'Content-Type';
  static const String appVersion = 'X-App-Version';
  static const String deviceOs = 'X-Device-OS';
  static const String deviceOsVersion = 'X-Device-OS-Version';
}

class ONetworkingClient extends DioForNative {
  static final envService = locator<EnvironmentService>();
  // TODO: Add default base url for production
  static final String _baseUrl = '${envService.environment.API_URL}api/${envService.environment.API_VERSION}/';

  // TODO: Add default required headers here
  static final Map<String, String> _defaultHeaders = {
    _ONetworkHeaderKeys.contentType: 'application/json',
    _ONetworkHeaderKeys.appVersion: AppInfoAmenity.instance.info.version,
    _ONetworkHeaderKeys.deviceOs: DeviceInfoAmenity.instance.info.osName,
    _ONetworkHeaderKeys.deviceOsVersion: DeviceInfoAmenity.instance.info.osVersion,
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
