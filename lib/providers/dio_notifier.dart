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

  List<File> selectedFiles = [];
  int selectedFilesSize = 0;

  final CancelToken _cancelToken = CancelToken();

  double get progress => _progress;
  int get progressPercentage => _progressPercentage;

  CancelToken get cancelToken => _cancelToken;

  UploadFilesSuccess? uploadFilesSuccess;
  UploadFilesFailure? uploadFilesFailure;
  UploadFileSuccess? uploadFileSuccess;
  UploadFileFailure? uploadFileFailure;

  FetchFilesMetadataSuccess? fetchFilesMetadataSuccess;
  FetchFilesMetadataFailure? fetchFilesMetadataFailure;

  set apiStatus(ApiStatus? value) {
    _dioService.apiStatus = value ?? ApiStatus.init;
    notifyListeners();
  }

  Stream<ApiStatus> get apiStatusStream => _dioService.apiStatusStream;
  ApiStatus? get apiStatus => _dioService.apiStatusStream.valueOrNull;

  set miniApiStatus(ApiStatus? value) {
    _dioService.miniApiStatus = value ?? ApiStatus.init;
    notifyListeners();
  }

  Stream<ApiStatus> get miniApiStatusStream => _dioService.miniApiStatusStream;
  ApiStatus? get miniApiStatus => _dioService.miniApiStatusStream.valueOrNull;

  Future<File> createDummyFile() async {
    return await _dioService.createDummyFile();
  }

  Future<void> uploadFilesAnonymous(
    List<File> files,
    void Function(int, int)? onSendProgress,
  ) async {
    selectedFiles = files;
    apiStatus = ApiStatus.loading;
    notifyListeners();
    Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFiles() async {
      final odinRepository = OdinRepository();

      selectedFilesSize = 0;
      for (var file in files) {
        selectedFilesSize += await file.length();
      }

      notifyListeners();

      final response = await odinRepository.uploadFilesAnonymous(
        request: UploadFilesRequest(
          files: files,
          totalFileSize: selectedFilesSize,
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
      apiStatus = ApiStatus.success;
      uploadFilesSuccess = success;
      uploadFilesFailure = null;
      notifyListeners();
      logger.d('[DioService]: UploadFilesSuccess ${success.message}');
    }

    void onFailure(UploadFilesFailure failure) {
      apiStatus = ApiStatus.failed;
      uploadFilesSuccess = null;
      uploadFilesFailure = failure;
      notifyListeners();
      logger.d('[DioService]: UploadFilesFailure ${failure.message}');
    }

    final response = await oNetwork<UploadFilesSuccess, UploadFilesFailure>(uploadFiles);

    response.resolve(onSuccess, onFailure);
  }

  Future<void> uploadFileAnonymous(
    File file,
    void Function(int, int)? onSendProgress,
  ) async {
    selectedFiles = [file];
    apiStatus = ApiStatus.loading;
    notifyListeners();

    Future<Result<UploadFileSuccess, UploadFileFailure>> uploadFile() async {
      final odinRepository = OdinRepository();

      selectedFilesSize = await file.length();
      notifyListeners();

      final response = await odinRepository.uploadFileAnonymous(
        request: UploadFileRequest(
          file: file,
          fileSize: selectedFilesSize,
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
      apiStatus = ApiStatus.success;
      uploadFileSuccess = success;
      uploadFileFailure = null;
      notifyListeners();
      logger.d('[DioService]: UploadFilesSuccess ${success.message}');
    }

    void onFailure(UploadFileFailure failure) {
      apiStatus = ApiStatus.failed;
      uploadFileSuccess = null;
      uploadFileFailure = failure;
      notifyListeners();
      logger.d('[DioService]: UploadFilesFailure ${failure.message}');
    }

    final response = await oNetwork<UploadFileSuccess, UploadFileFailure>(uploadFile);

    response.resolve(onSuccess, onFailure);
  }

  Future<void> fetchFilesMetadata(
    String token,
    void Function(int, int)? onReceiveProgress,
  ) async {
    miniApiStatus = ApiStatus.loading;
    notifyListeners();
    Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>> _fetchFilesMetadata() async {
      final odinRepository = OdinRepository();

      final response = await odinRepository.fetchFilesMetadata(
        request: FetchFilesMetadataRequest(
          token: token,
          onReceiveProgress: (count, total) {
            _progress = count / total;
            _progressPercentage = (_progress * 100).toInt();

            onReceiveProgress?.call(count, total);

            notifyListeners();
          },
          cancelToken: _cancelToken,
        ),
      );

      return response;
    }

    void onSuccess(FetchFilesMetadataSuccess success) async {
      miniApiStatus = ApiStatus.success;
      fetchFilesMetadataSuccess = success;
      fetchFilesMetadataFailure = null;
      notifyListeners();
      logger.d('[DioService]: FetchFilesMetadataSuccess ${success.message}');
    }

    void onFailure(FetchFilesMetadataFailure failure) {
      miniApiStatus = ApiStatus.failed;
      fetchFilesMetadataSuccess = null;
      fetchFilesMetadataFailure = failure;
      notifyListeners();
      logger.d('[DioService]: FetchFilesMetadataFailure ${failure.message}');
    }

    final response = await oNetwork<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>(_fetchFilesMetadata);

    response.resolve(onSuccess, onFailure);
  }

  Future<void> cancelCurrentRequest() async {
    apiStatus = ApiStatus.failed;
    _cancelToken.cancel();
    notifyListeners();
  }

  Future<void> cancelMiniRequest() async {
    miniApiStatus = ApiStatus.failed;
    _cancelToken.cancel();
    notifyListeners();
  }
}
