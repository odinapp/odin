import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/services/dio_service.dart';
import 'package:odin/providers/pending_uploads_notifier.dart';
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

  FetchConfigSuccess? fetchConfigSuccess;
  FetchConfigFailure? fetchConfigFailure;

  DownloadFileSuccess? downloadFileSuccess;
  DownloadFileFailure? downloadFileFailure;

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
    _progress = 0;
    _progressPercentage = 0;
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
            if (total > 0) {
              _progress = count / total;
              _progressPercentage = (_progress * 100).toInt();
            }

            onSendProgress?.call(count, total);

            notifyListeners();
          },
          cancelToken: _cancelToken,
        ),
      );

      return response;
    }

    void onSuccess(UploadFilesSuccess success) {
      apiStatus = ApiStatus.success;
      uploadFilesSuccess = success;
      uploadFilesFailure = null;
      notifyListeners();
      logger.d('[DioService]: UploadFilesSuccess ${success.message}');
      final delete = success.deleteToken;
      if (delete != null && delete.isNotEmpty) {
        unawaited(_persistPendingUpload(success, delete));
      }
    }

    void onFailure(UploadFilesFailure failure) {
      apiStatus = ApiStatus.failed;
      uploadFilesSuccess = null;
      uploadFilesFailure = failure;
      notifyListeners();
      logger.d('[DioService]: UploadFilesFailure ${failure.message}');
    }

    final response = await oNetwork<UploadFilesSuccess, UploadFilesFailure>(
      uploadFiles,
    );

    response.resolve(onSuccess, onFailure);
  }

  Future<void> uploadFileAnonymous(
    File file,
    void Function(int, int)? onSendProgress,
  ) async {
    selectedFiles = [file];
    _progress = 0;
    _progressPercentage = 0;
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
            if (total > 0) {
              _progress = count / total;
              _progressPercentage = (_progress * 100).toInt();
            }

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

    final response = await oNetwork<UploadFileSuccess, UploadFileFailure>(
      uploadFile,
    );

    response.resolve(onSuccess, onFailure);
  }

  Future<void> fetchFilesMetadata(
    String token,
    void Function(int, int)? onReceiveProgress,
  ) async {
    miniApiStatus = ApiStatus.loading;
    notifyListeners();
    Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>>
    _fetchFilesMetadata() async {
      final odinRepository = OdinRepository();

      final response = await odinRepository.fetchFilesMetadata(
        request: FetchFilesMetadataRequest(
          token: token,
          onReceiveProgress: (count, total) {
            if (total > 0) {
              _progress = count / total;
              _progressPercentage = (_progress * 100).toInt();
              notifyListeners();
            }

            onReceiveProgress?.call(count, total);
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

    final response =
        await oNetwork<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>(
          _fetchFilesMetadata,
        );

    response.resolve(onSuccess, onFailure);
  }

  Future<void> fetchConfig(void Function(int, int)? onReceiveProgress) async {
    notifyListeners();
    Future<Result<FetchConfigSuccess, FetchConfigFailure>>
    _fetchConfig() async {
      final odinRepository = OdinRepository();

      final response = await odinRepository.fetchConfig(
        request: FetchConfigRequest(
          onReceiveProgress: (count, total) {
            if (total > 0) {
              _progress = count / total;
              _progressPercentage = (_progress * 100).toInt();
              notifyListeners();
            }

            onReceiveProgress?.call(count, total);
          },
          cancelToken: _cancelToken,
        ),
      );

      return response;
    }

    void onSuccess(FetchConfigSuccess success) async {
      fetchConfigSuccess = success;
      fetchConfigFailure = null;
      notifyListeners();
      logger.d('[DioService]: FetchConfigSuccess ${success.message}');
    }

    void onFailure(FetchConfigFailure failure) {
      fetchConfigSuccess = null;
      fetchConfigFailure = failure;
      notifyListeners();
      logger.d('[DioService]: FetchConfigFailure ${failure.message}');
    }

    final response = await oNetwork<FetchConfigSuccess, FetchConfigFailure>(
      _fetchConfig,
    );

    response.resolve(onSuccess, onFailure);
  }

  Future<void> downloadFile(
    String token,
    String fileName,
    void Function(int, int)? onReceiveProgress,
  ) async {
    _progress = 0;
    _progressPercentage = 0;
    apiStatus = ApiStatus.loading;
    notifyListeners();
    Future<Result<DownloadFileSuccess, DownloadFileFailure>>
    _downloadFile() async {
      final odinRepository = OdinRepository();

      final response = await odinRepository.downloadFile(
        request: DownloadFileRequest(
          token: token,
          savePath: fileName,
          onReceiveProgress: (count, total) {
            if (total > 0) {
              _progress = count / total;
              _progressPercentage = (_progress * 100).toInt();
              notifyListeners();
            }

            onReceiveProgress?.call(count, total);
          },
          cancelToken: _cancelToken,
        ),
      );

      return response;
    }

    void onSuccess(DownloadFileSuccess success) async {
      downloadFileSuccess = success;
      downloadFileFailure = null;
      // Reset main status so desktop stay on the download form; mobile uses
      // [downloadFileSuccess] for the success screen.
      apiStatus = ApiStatus.init;
      notifyListeners();
      logger.d('[DioService]: DownloadFileSuccess ${success.message}');
    }

    void onFailure(DownloadFileFailure failure) {
      downloadFileSuccess = null;
      downloadFileFailure = failure;
      apiStatus = ApiStatus.init;
      notifyListeners();
      logger.d('[DioService]: DownloadFileFailure ${failure.message}');
    }

    final response = await oNetwork<DownloadFileSuccess, DownloadFileFailure>(
      _downloadFile,
    );

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

  Future<void> _persistPendingUpload(
    UploadFilesSuccess success,
    String deleteUrl,
  ) async {
    try {
      await locator<PendingUploadsNotifier>().recordPendingUpload(
        shareToken: success.token,
        deleteUrl: deleteUrl,
        fileSummary: _selectedFilesSummaryLabel(),
      );
    } catch (e, st) {
      logger.e('recordPendingUpload', error: e, stackTrace: st);
    }
  }

  String? _selectedFilesSummaryLabel() {
    if (selectedFiles.isEmpty) return null;
    if (selectedFiles.length == 1) {
      return selectedFiles.first.path.split(RegExp(r'[/\\]')).last;
    }
    return '${selectedFiles.length} files';
  }
}
