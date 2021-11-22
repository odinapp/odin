import 'package:flutter/material.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';

class FileNotifier with ChangeNotifier {
  final _fileService = locator<FileService>();
  bool get loading => _fileService.loading;
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
}
