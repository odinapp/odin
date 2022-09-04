import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:odin/services/dio_service.dart';
import 'package:odin/services/locator.dart';

class DioNotifier with ChangeNotifier {
  final _dioService = locator<DioService>();
  double _progress = 0;
  int _progressPercentage = 0;

  CancelToken _cancelToken = CancelToken();

  double get progress => _progress;
  int get progressPercentage => _progressPercentage;

  CancelToken get cancelToken => _cancelToken;

  Future<File> createDummyFile() async {
    return await _dioService.createDummyFile();
  }

  Future<String> uploadFilesAnonymous(
    List<File> files,
    void Function(int, int)? onSendProgress,
  ) async {
    return await _dioService.uploadFilesAnonymous(
      files,
      (count, total) {
        _progress = count / total;
        _progressPercentage = (_progress * 100).toInt();

        onSendProgress?.call(count, total);

        notifyListeners();
      },
      _cancelToken,
    );
  }

  Future<String> uploadFileAnonymous(
    File file,
    void Function(int, int)? onSendProgress,
  ) async {
    _cancelToken = CancelToken();
    return await _dioService.uploadFileAnonymous(
      file,
      (count, total) {
        _progress = count / total;
        _progressPercentage = (_progress * 100).toInt();

        onSendProgress?.call(count, total);

        notifyListeners();
      },
      _cancelToken,
    );
  }

  Future<void> cancelCurrentRequest() async {
    _cancelToken.cancel();
  }
}
