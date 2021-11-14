import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odin/services/logger.dart';

class HTTPService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://newsapi.org/v2',
    connectTimeout: 5000,
    receiveTimeout: 3000,
  ));

  Future<Response?> get({
    required uri,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    final String time = DateTime.now().toString();
    logger.d("GET:: $time : ${uri.toString()}");
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final query = {'apiKey': dotenv.env['NEWS_API_KEY']};
      query.addAll(body ?? {});
      final Response response = await _dio.get(uri,
          queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      logger.d("Request : ${response.realUri}");
      if (response.statusCode != 200) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Get Request Failed.", e, st);
      return null;
    }
  }

  Future<Response?> post({
    required uri,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    final String time = DateTime.now().toString();
    logger.d("POST:: $time : ${uri.toString()}");
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final query = {'apiKey': dotenv.env['NEWS_API_KEY']};
      query.addAll(body ?? {});
      final Response response = await _dio.post(uri,
          queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      logger.d("Request : ${response.realUri}");
      if (response.statusCode != 200) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Post Request Failed.", e, st);
      return null;
    }
  }
}
