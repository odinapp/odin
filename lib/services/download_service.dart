import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final RandomService _randomService = locator<RandomService>();
  String progress = '0%';
  bool downloading = false;

  Dio dio = Dio();
  Future<String> _getFilePath() async {
    final fileName = _randomService.getRandomString(10);
    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      dir = await getTemporaryDirectory();
    } else {
      dir = await getDownloadsDirectory();
    }
    String path = join(dir?.path ?? '', fileName + ".odin");
    logger.d("File path : $path");
    return path;
  }

  Future<File> downloadFile(String url) async {
    final filePath = await _getFilePath();
    progress = '0%';
    downloading = true;
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (rcv, total) {
        progress = ((rcv / total) * 100).toStringAsFixed(0) + "%";
      },
      deleteOnError: true,
    );
    downloading = false;
    return File(filePath);
  }
}
