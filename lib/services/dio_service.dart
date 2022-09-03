import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:path_provider/path_provider.dart';

class DioService {
  static final dio = Dio();
  static final envService = locator<EnvironmentService>();
  static final baseUrl = '${envService.environment.API_URL}api/${envService.environment.API_VERSION}';
  static final successfulStatusCode = int.parse(envService.environment.SUCCESSFUL_STATUS_CODE);

  Future<File> createDummyFile() async {
    // Create a dummy file
    const exampleString = 'Example file contents';
    final tempDir = await getTemporaryDirectory();
    final exampleFile = File('${tempDir.path}/example.txt')
      ..createSync()
      ..writeAsStringSync(exampleString);

    return exampleFile;
  }

  Future<String> uploadFileAnonymous(
    File file,
  ) async {
    try {
      logger.d('[DioService]: baseUrl: $baseUrl');
      String fileName = file.path.split('/').last;
      final request = {
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      };
      logger.d('[DioService]: fileName: $fileName');
      logger.d('[DioService]: request: $request');
      FormData formData = FormData.fromMap(request);
      final response = await post(path: "file/upload", data: formData);
      return response?.data['id'] ?? '';
    } catch (e) {
      logger.e('[DioService]: Error uploading file: $e');
      return '';
    }
  }

  // Basic dio get request
  Future<Response?> get({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response =
          await dio.get("$baseUrl/$path", queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      if (response.statusCode != successfulStatusCode) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Get Request Failed.", e, st);
      return null;
    }
  }

  // Basic dio post request
  Future<Response?> post({
    required String path,
    dynamic data,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response =
          await dio.post("$baseUrl/$path", data: data, queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      if (response.statusCode != successfulStatusCode) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Post Request Failed.", e, st);
      return null;
    }
  }
}
