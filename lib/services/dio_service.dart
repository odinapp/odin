import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/utilities/networking.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class DioService {
  static final dio = Dio();
  static final envService = locator<EnvironmentService>();
  static final randomService = locator<RandomService>();
  static final baseUrl = '${envService.environment.API_URL}api/${envService.environment.API_VERSION}';
  static final successfulStatusCode = int.parse(envService.environment.SUCCESSFUL_STATUS_CODE);

  final _apiStatusSubject = BehaviorSubject<ApiStatus>.seeded(ApiStatus.init);

  ValueStream<ApiStatus> get apiStatusStream => _apiStatusSubject.stream;

  set apiStatus(ApiStatus v) => _apiStatusSubject.add(v);

  Future<File> createDummyFile() async {
    // Create a dummy file
    const exampleString = 'Example file contents';
    final tempDir = await getTemporaryDirectory();
    final exampleFile = File('${tempDir.path}/example.txt')
      ..createSync()
      ..writeAsStringSync(exampleString);

    return exampleFile;
  }
}
