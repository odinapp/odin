import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/services/dio_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/utilities/networking.dart';

class DioNotifier with ChangeNotifier {
  final _dioService = locator<DioService>();
  double _progress = 0;
  int _progressPercentage = 0;

  final CancelToken _cancelToken = CancelToken();

  double get progress => _progress;
  int get progressPercentage => _progressPercentage;

  CancelToken get cancelToken => _cancelToken;

  Future<File> createDummyFile() async {
    return await _dioService.createDummyFile();
  }

  Future<void> uploadFilesAnonymous(
    List<File> files,
    void Function(int, int)? onSendProgress,
  ) async {
    Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFiles() async {
      final odinRepository = OdinRepository();

      final response = await odinRepository.uploadFilesAnonymous(
        request: UploadFilesRequest(
          files: files,
          onSendProgress: (count, total) {
            _progress = count / total;
            _progressPercentage = (_progress * 100).toInt();

            onSendProgress?.call(count, total);

            notifyListeners();
          },
          cancelToken: _cancelToken,
        ),
      );

      return response;
    }

    void onSuccess(UploadFilesSuccess success) async {
      logger.d('[DioService]: UploadFilesSuccess ${success.message}');
    }

    void onFailure(UploadFilesFailure failure) {
      logger.d('[DioService]: UploadFilesFailure ${failure.message}');
    }

    final response = await oNetwork<UploadFilesSuccess, UploadFilesFailure>(uploadFiles);

    response.resolve(onSuccess, onFailure);
  }

  Future<void> uploadFileAnonymous(
    File file,
    void Function(int, int)? onSendProgress,
  ) async {
    Future<Result<UploadFileSuccess, UploadFileFailure>> uploadFile() async {
      final odinRepository = OdinRepository();

      final response = await odinRepository.uploadFileAnonymous(
        request: UploadFileRequest(
          file: file,
          onSendProgress: (count, total) {
            _progress = count / total;
            _progressPercentage = (_progress * 100).toInt();

            onSendProgress?.call(count, total);

            notifyListeners();
          },
          cancelToken: _cancelToken,
        ),
      );

      return response;
    }

    void onSuccess(UploadFileSuccess success) async {
      logger.d('[DioService]: UploadFilesSuccess ${success.message}');
    }

    void onFailure(UploadFileFailure failure) {
      logger.d('[DioService]: UploadFilesFailure ${failure.message}');
    }

    final response = await oNetwork<UploadFileSuccess, UploadFileFailure>(uploadFile);

    response.resolve(onSuccess, onFailure);
  }

  Future<void> cancelCurrentRequest() async {
    _cancelToken.cancel();
  }
}
