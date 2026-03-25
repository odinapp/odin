import 'package:dio/dio.dart';
import 'package:odin/services/logger.dart';

class OTokenInvalidInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    ///401 is for authentication
    if (response.statusCode == 401) {
      // Log out and redirect to login page
    } else if (response.statusCode == 403) {
      ///403 is for authorization
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('status code : ${err.response?.statusCode}');

    handler.next(err);
  }
}
