import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/logger.dart';

class ShortnerService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.shrtco.de/v2/',
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
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response = await _dio.get(uri,
          queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      logger.d("Request : ${response.realUri}");
      if (response.statusCode != 201) {
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
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response = await _dio.post(uri,
          queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      logger.d("Request : ${response.realUri}");
      if (response.statusCode != 201) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Post Request Failed.", e, st);
      return null;
    }
  }

  Future<String?> getShortUrl({required String url}) async {
    final Response? response = await post(uri: 'shorten?url=$url');
    if (response != null) {
      return response.data["result"]["full_short_link"];
    } else {
      return null;
    }
  }
}
