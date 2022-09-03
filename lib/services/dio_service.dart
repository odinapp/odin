import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:path_provider/path_provider.dart';

class DioService {
  static final dio = Dio();
  static final envService = locator<EnvironmentService>();
  static final baseUrl = '${envService.environment.API_URL}/api/${envService.environment.API_VERSION}';

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
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await dio.post("$baseUrl", data: formData);
      return response.data['id'];
    } catch (e) {
      logger.e('[DioService]: Error uploading file: $e');
      return '';
    }
  }
}
