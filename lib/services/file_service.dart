import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:odin/services/github_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/zip_service.dart';

class FileService {
  final _githubService = locator<GithubService>();
  final _zipService = locator<ZipService>();
  bool loading = false;

  Future<String?> getLinkFromFilePicker() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    final String? _path;
    if (result != null) {
      loading = true;
      List<File> files = result.paths.map((path) => File(path!)).toList();
      final zippedFile = await _zipService.zipFile(fileToZips: files);
      _path = await _githubService.uploadFileAnonymous(zippedFile);
      loading = false;
    } else {
      // User canceled the picker
      _path = null;
    }
    return _path;
  }

  Future<String?> getLinkFromDroppedFiles(List<Uri> urls) async {
    final String? _path;
    if (urls.isNotEmpty) {
      loading = true;
      final List<File> fileToZips =
          urls.map((e) => File(e.toFilePath())).toList();
      final zippedFile = await _zipService.zipFile(fileToZips: fileToZips);
      _path = await _githubService.uploadFileAnonymous(zippedFile);
      loading = false;
    } else {
      _path = null;
    }
    return _path;
  }
}
