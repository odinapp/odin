part of 'networking_box.dart';

abstract class _ONetworkHeaderKeys {
  static const String contentType = 'Content-Type';
  static const String appVersion = 'X-App-Version';
  static const String deviceOs = 'X-Device-OS';
  static const String deviceOsVersion = 'X-Device-OS-Version';
}

/// HTTP client with shared Odin headers and simple request timing logs.
/// Wraps [Dio] because Dio 5+ cannot be subclassed.
class ONetworkingClient {
  ONetworkingClient._(this.dio);

  final Dio dio;

  Interceptors get interceptors => dio.interceptors;

  static final envService = locator<EnvironmentService>();
  static final String _baseUrl =
      '${envService.environment.API_URL}api/${envService.environment.API_VERSION}/';

  static final Map<String, String> _defaultHeaders = {
    _ONetworkHeaderKeys.contentType: 'application/json',
    _ONetworkHeaderKeys.appVersion: AppInfoAmenity.instance.info.version,
    _ONetworkHeaderKeys.deviceOs: DeviceInfoAmenity.instance.info.osName,
    _ONetworkHeaderKeys.deviceOsVersion:
        DeviceInfoAmenity.instance.info.osVersion,
  };

  factory ONetworkingClient({String? authorizationToken, String? timezone}) {
    final d = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          ..._defaultHeaders,
          if (authorizationToken != null) ...{
            'Authorization': 'Bearer $authorizationToken',
          },
          if (timezone != null) ...{'Timezone': timezone},
        },
        validateStatus: (_) => true,
        connectTimeout: const Duration(milliseconds: 3000),
      ),
    );
    final client = ONetworkingClient._(d);
    logger.d('Headers : $_defaultHeaders');
    return client;
  }

  factory ONetworkingClient.fromOptions(
    ONetworkingOptions options, {
    String? authorizationToken,
    String? timezone,
  }) {
    final d = Dio(
      BaseOptions(
        baseUrl: options.baseUrl ?? _baseUrl,
        headers: {
          ..._defaultHeaders,
          if (options.headers != null) ...options.headers!,
          if (authorizationToken != null) ...{
            'Authorization': 'Bearer $authorizationToken',
          },
          if (timezone != null) ...{'Timezone': timezone},
        },
        responseType: options.responseType ?? ResponseType.json,
        validateStatus: (_) => true,
        connectTimeout: const Duration(milliseconds: 3000),
      ),
    );
    return ONetworkingClient._(d);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final response = await dio.post<T>(
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

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final response = await dio.get<T>(
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
