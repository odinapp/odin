import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ZipService {
  final RandomService _randomService = locator<RandomService>();

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
    return File(zipFilePath);
  }
}
