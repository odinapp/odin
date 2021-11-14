import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/logger.dart';

class ShortnerService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.shrtco.de/v2/',
    connectTimeout: 5000,
    receiveTimeout: 3000,
  ));

  Future<String?> shortUrl({required String url}) async {
    final String time = DateTime.now().toString();
    logger.d("GET:: $time : ${url.toString()}");
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Response response = await _dio.post('shorten?url=$url');
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      logger.d("Request : ${response.realUri}");
      if (response.statusCode != 201) {
        throw HttpException(response.statusCode.toString());
      }
      return response.data["result"]["full_short_link"];
    } catch (e, st) {
      logger.e("Get Request Failed.", e, st);
      return null;
    }
  }
}
