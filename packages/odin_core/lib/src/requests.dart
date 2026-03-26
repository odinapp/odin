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
    required this.totalFileSize,
    super.onSendProgress,
    super.cancelToken,
  });

  final List<File> files;
  final int totalFileSize;
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
    super.onReceiveProgress,
    super.cancelToken,
  });

  final String token;
  final String savePath;
}

class FetchConfigRequest extends RepositoryGetRequest {
  FetchConfigRequest({super.onReceiveProgress, super.cancelToken});
}
