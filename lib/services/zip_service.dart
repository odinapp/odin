import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/utilities/byte_formatter.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ZipService {
  final RandomService _randomService = locator<RandomService>();
  String linkTitle = "";
  String linkDesc = "";

  Future<File> zipFile({
    required List<File> fileToZips,
  }) async {
    logger.d('Started Zipping Files');
    final ZipFileEncoder encoder = ZipFileEncoder();
    final Directory zipFileSaveDirectory = await getTemporaryDirectory();
    final zipFileSavePath = zipFileSaveDirectory.path;
    // Manually create a zip at the zipFilePath
    final String zipFilePath = join(zipFileSavePath,
        "${basename(fileToZips.first.path).replaceAll('.', '_')}_${_randomService.getRandomString(15)}.zip");
    encoder.create(zipFilePath);
    // Add all the files to the zip file
    for (final File fileToZip in fileToZips) {
      encoder.addFile(fileToZip);
    }
    encoder.close();
    logger.d('Finished Zipping Files');
    if (fileToZips.length == 1) {
      linkTitle = basename(fileToZips.first.path);
    } else if (fileToZips.length == 2) {
      linkTitle = "${basename(fileToZips.first.path)} & ${fileToZips.length - 1} more file.";
    } else {
      linkTitle = "${basename(fileToZips.first.path)} & ${fileToZips.length - 1} more files.";
    }
    linkDesc = formatBytes(File(zipFilePath).lengthSync(), 2);
    return File(zipFilePath);
  }

  Future<String> unzipFile(File file) async {
    final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    final outDirectory = file.path.replaceAll('.zip', '');
    for (final zfile in archive) {
      final filename = zfile.name;
      if (zfile.isFile) {
        final data = zfile.content as List<int>;
        File(join(outDirectory, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(join(outDirectory, filename)).create(recursive: true);
      }
    }
    file.deleteSync(); // Delete the original ZIP file
    return Directory(outDirectory).path;
  }
}
