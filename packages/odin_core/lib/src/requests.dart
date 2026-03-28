import 'dart:io';

import 'package:dio/dio.dart';

abstract class RepositoryPostRequest {
  RepositoryPostRequest({this.onSendProgress, this.cancelToken});

  final ProgressCallback? onSendProgress;
  final CancelToken? cancelToken;
}

abstract class RepositoryGetRequest {
  RepositoryGetRequest({this.onReceiveProgress, this.cancelToken});

  final ProgressCallback? onReceiveProgress;
  final CancelToken? cancelToken;
}

class UploadFilesRequest extends RepositoryPostRequest {
  UploadFilesRequest({
    required this.files,
    this.inputPaths,
    this.encrypt = true,
    super.onSendProgress,
    super.cancelToken,
  });

  final List<File> files;
  final List<String>? inputPaths;
  final bool encrypt;
}

class FetchFilesMetadataRequest extends RepositoryGetRequest {
  FetchFilesMetadataRequest({
    required this.token,
    super.onReceiveProgress,
    super.cancelToken,
  });

  final String token;
}

class DownloadFileRequest extends RepositoryGetRequest {
  DownloadFileRequest({
    required this.token,
    required this.savePath,
    this.requireEncrypted = false,
    this.autoExtractArchives = true,
    super.onReceiveProgress,
    super.cancelToken,
  });

  final String token;
  final String savePath;
  final bool requireEncrypted;
  final bool autoExtractArchives;
}

class FetchConfigRequest extends RepositoryGetRequest {
  FetchConfigRequest({super.onReceiveProgress, super.cancelToken});
}
