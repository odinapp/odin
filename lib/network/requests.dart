part of './repository.dart';

abstract class RepositoryPostRequest {
  final void Function(int, int)? onSendProgress;
  final CancelToken? cancelToken;

  RepositoryPostRequest({
    this.onSendProgress,
    this.cancelToken,
  });
}

class UploadFilesRequest extends RepositoryPostRequest {
  final List<File> files;

  UploadFilesRequest({
    required this.files,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) : super(
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        );
}

class UploadFileRequest extends RepositoryPostRequest {
  final File file;

  UploadFileRequest({required this.file, void Function(int, int)? onSendProgress, CancelToken? cancelToken})
      : super(
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        );
}
