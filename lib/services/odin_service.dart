import 'package:odin/services/dio_service.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/zip_service.dart';

class OdinService {
  final _fileService = locator<FileService>();
  final _zipService = locator<ZipService>();
  final _dioService = locator<DioService>();

  Future<void> uploadFiles({bool asZip = true}) async {
    final dummyFiles = await _fileService.pickMultipleFiles();
    if (dummyFiles != null) {
      if (asZip) {
        final dummyFile = await _zipService.convertMultipleFilesIntoZip(dummyFiles);
        if (dummyFile != null) _dioService.uploadFileAnonymous(dummyFile);
      } else {
        for (final dummyFile in dummyFiles) {
          _dioService.uploadFileAnonymous(dummyFile);
        }
      }
    }
  }
}
