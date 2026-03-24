import 'package:dio/dio.dart';
import 'package:odin/services/logger.dart';

class ONetworkLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('RequestOptions : $options');
    logger.d('RequestOptions Headers: ${options.headers}');
    logger.d('RequestOptions.url : ${options.uri}');
    logger.d('RequestOptions.data : ${options.data}');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('Response : $response');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.d('Error : $err');

    handler.next(err);
  }
}
