import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:odin/services/data_service.dart';
import 'package:odin/services/github_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/zip_service.dart';

class FilepickerService {
  // final _dataService = locator<DataService>();
  final _githubService = locator<GithubService>();
  final _zipService = locator<ZipService>();

  Future<String?> getFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    final String? _path;
    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      final int length = files.length;
      if (length > 1) {
        final zippedFile = await _zipService.zipFile(fileToZips: files);
        _path = await _githubService.uploadFileAnonymous(zippedFile);
      } else {
        _path = await _githubService.uploadFileAnonymous(files.first);
      }
    } else {
      // User canceled the picker
      _path = null;
    }
    return _path;
  }
}
