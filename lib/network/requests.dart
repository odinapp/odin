part of './repository.dart';

abstract class RepositoryPostRequest {
  final void Function(int, int)? onSendProgress;
  final CancelToken? cancelToken;

  RepositoryPostRequest({
    this.onSendProgress,
    this.cancelToken,
  });
}

abstract class RepositoryGetRequest {
  final void Function(int, int)? onReceiveProgress;
  final CancelToken? cancelToken;

  RepositoryGetRequest({
    this.onReceiveProgress,
    this.cancelToken,
  });
}

class UploadFilesRequest extends RepositoryPostRequest {
  final List<File> files;
  final int totalFileSize;

  UploadFilesRequest({
    required this.files,
    required this.totalFileSize,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) : super(
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        );
}

class UploadFileRequest extends RepositoryPostRequest {
  final File file;
  final int fileSize;

  UploadFileRequest({
    required this.file,
    required this.fileSize,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) : super(
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        );
}

class FetchFilesMetadataRequest extends RepositoryGetRequest {
  final String token;

  FetchFilesMetadataRequest({
    required this.token,
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) : super(
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
        );
}

class FetchConfigRequest extends RepositoryGetRequest {
  FetchConfigRequest({
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) : super(
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
        );
}

class DownloadFileRequest extends RepositoryGetRequest {
  final String token;
  final String savePath;

  DownloadFileRequest({
    required this.token,
    required this.savePath,
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) : super(
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
        );
}
