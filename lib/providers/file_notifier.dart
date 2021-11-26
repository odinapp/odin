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
    await _fileService.getLinkFromFilePicker();
    notifyListeners();
  }

  Future<void> getLinkFromDroppedFiles(List<Uri> urls) async {
    await _fileService.getLinkFromDroppedFiles(urls);
    notifyListeners();
  }

  Future<String> getFileFromToken(String token) async {
    final _filePath = await _fileService.getFileFromToken(token);
    notifyListeners();
    return _filePath;
  }
}
