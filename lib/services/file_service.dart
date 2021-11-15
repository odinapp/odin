import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:odin/services/github_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/zip_service.dart';

class FileService {
  final _githubService = locator<GithubService>();
  final _zipService = locator<ZipService>();
  bool loading = false;
  bool processing = false;
  String? fileLink;

  Future<void> getLinkFromFilePicker() async {
    fileLink = null;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    final String? _path;
    if (result != null) {
      loading = true;
      processing = true;
      List<File> files = result.paths.map((path) => File(path!)).toList();
      final zippedFile = await _zipService.zipFile(fileToZips: files);
      processing = false;
      _path = await _githubService.uploadFileAnonymous(zippedFile);
      loading = false;
    } else {
      // User canceled the picker
      _path = null;
    }
    fileLink = _path;
  }

  Future<void> getLinkFromDroppedFiles(List<Uri> urls) async {
    fileLink = null;
    final String? _path;
    if (urls.isNotEmpty) {
      loading = true;
      processing = true;
      final List<File> fileToZips =
          urls.map((e) => File(e.toFilePath())).toList();
      final zippedFile = await _zipService.zipFile(fileToZips: fileToZips);
      processing = false;
      _path = await _githubService.uploadFileAnonymous(zippedFile);
      loading = false;
    } else {
      _path = null;
    }
    fileLink = _path;
  }
}
