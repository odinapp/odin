// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:odin/services/logger.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class DownloadService {
//   String progress = '0%';
//   bool downloading = false;

//   Dio dio = Dio();
//   Future<String> _getFilePath(String fileName) async {
//     Directory? dir;
//     if (Platform.isAndroid) {
//       var status = await Permission.storage.status;
//       if (!status.isGranted) {
//         await Permission.storage.request();
//       }
//       dir = await getTemporaryDirectory();
//     } else if (Platform.isIOS) {
//       dir = await getTemporaryDirectory();
//     } else {
//       dir = await getDownloadsDirectory();
//     }
//     String path = join(dir?.path ?? '', fileName);
//     logger.d("File path : $path");
//     return path;
//   }

//   Future<File> downloadFile(String url) async {
//     progress = '0%';
//     downloading = true;
//     Response response = await Dio().get(
//       url,
//       options: Options(
//           followRedirects: false,
//           validateStatus: (status) {
//             return (status ?? 0) < 500;
//           }),
//     );
//     final filePath = await _getFilePath(basename(response.headers.map["location"]?[0] ?? ''));
//     await dio.download(
//       url,
//       filePath,
//       onReceiveProgress: (rcv, total) {
//         progress = "${((rcv / total) * 100).toStringAsFixed(0)}%";
//       },
//       deleteOnError: true,
//     );
//     downloading = false;
//     return File(filePath);
//   }
// }
