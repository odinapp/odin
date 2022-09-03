import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';

class FileNotifier with ChangeNotifier {
  final _fileService = locator<FileService>();
  bool get uploading => _fileService.uploading;
  bool get downloading => _fileService.downloading;
  bool get processing => _fileService.processing;
  String? get fileLink => _fileService.fileLink;
  String get zipfileName => _fileService.zipfileName;

  Future<void> getLinkFromFilePicker() async {
    // await _fileService.getLinkFromFilePicker();
    notifyListeners();
  }

  Future<void> getLinkFromDroppedFiles(List<XFile> xfiles) async {
    // await _fileService.getLinkFromDroppedFiles(xfiles);
    notifyListeners();
  }

  Future<String> getFileFromToken(String token) async {
    // final filePath = await _fileService.getFileFromToken(token);
    notifyListeners();
    // return filePath;
    return '';
  }
}
