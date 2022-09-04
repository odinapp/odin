import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:path_provider/path_provider.dart';

class DioService {
  static final dio = Dio();
  static final envService = locator<EnvironmentService>();
  static final randomService = locator<RandomService>();
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

  Future<String> uploadFilesAnonymous(
    List<File> files,
    void Function(int, int)? onSendProgress,
    CancelToken cancelToken,
  ) async {
    try {
      logger.d('[DioService]: baseUrl: $baseUrl');
      final apiUrl = '$baseUrl/file/upload';
      logger.d('[DioService]: apiUrl: $apiUrl');

      final formData = FormData();
      for (var file in files) {
        logger.d('[DioService]: fileName: ${file.path.split('/').last}');
        formData.files.addAll([
          MapEntry(
            "file",
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ),
        ]);
      }

      final directoryName = randomService.getRandomString(10);

      formData.fields.add(MapEntry("directoryName", directoryName));

      final response = await _post(
        path: "file/upload",
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      return response?.data['id'] ?? '';
    } catch (e) {
      logger.e('[DioService]: Error uploading files: $e');
      return '';
    }
  }

  Future<String> uploadFileAnonymous(
    File file,
    void Function(int, int)? onSendProgress,
    CancelToken cancelToken,
  ) async {
    try {
      logger.d('[DioService]: baseUrl: $baseUrl');
      final apiUrl = '$baseUrl/file/upload';
      logger.d('[DioService]: apiUrl: $apiUrl');

      String fileName = file.path.split('/').last;
      final directoryName = randomService.getRandomString(10);

      final multipartFile = await MultipartFile.fromFile(file.path, filename: fileName);
      final request = <String, dynamic>{
        'directoryName': directoryName,
      };

      request['media'] = multipartFile;

      logger.d('[DioService]: fileName: $fileName');
      logger.d('[DioService]: request: $request');
      FormData formData = FormData.fromMap(request);

      final response = await _post(
        path: "file/upload",
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return response?.data['id'] ?? '';
    } catch (e) {
      logger.e('[DioService]: Error uploading file: $e');
      return '';
    }
  }

  // Basic dio get request
  Future<Response?> _get({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? body,
    void Function(int, int)? onRecieveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response = await dio.get(
        "$baseUrl/$path",
        queryParameters: query,
        options: Options(
          headers: headers,
        ),
        onReceiveProgress: onRecieveProgress,
        cancelToken: cancelToken,
      );
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      if (response.statusCode != successfulStatusCode) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } on DioError catch (dioError) {
      final exception = Exception(
        '[${dioError.response?.statusCode ?? 0}]: ${dioError.message}',
      );
      logger.e('[${dioError.response?.statusCode ?? 0}]: ${dioError.response?.data ?? dioError.message}', exception,
          dioError.stackTrace);
    } catch (e, st) {
      logger.e("Get Request Failed.", e, st);
      return null;
    }
  }

  // Basic dio post request
  Future<Response?> _post({
    required String path,
    dynamic data,
    Map<String, String>? headers,
    Map<String, String>? body,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Response response = await dio.post(
        "$baseUrl/$path",
        data: data,
        queryParameters: body,
        options: Options(
          headers: headers,
          extra: body,
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      if (response.statusCode != successfulStatusCode) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } on DioError catch (dioError) {
      final exception = Exception(
        '[${dioError.response?.statusCode ?? 0}]: ${dioError.message}',
      );
      logger.e('[${dioError.response?.statusCode ?? 0}]: ${dioError.response?.data ?? dioError.message}', exception,
          dioError.stackTrace);
    } catch (e, st) {
      logger.e("Post Request Failed.", e, st);
      return null;
    }
  }
}
