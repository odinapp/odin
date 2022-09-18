part of './repository.dart';

enum OdinFailureReason {
  unknown,
  invalidRequest,
}

class UploadFilesFailure extends RepositoryFailure {
  final OdinFailureReason odinFailureReason;

  UploadFilesFailure({
    int? statusCode,
    String? message,
    this.odinFailureReason = OdinFailureReason.unknown,
  }) : super(statusCode: statusCode, message: message);
}

class UploadFilesSuccess extends RepositorySuccess {
  final String token;
  UploadFilesSuccess({
    String? message,
    required this.token,
  }) : super(message: message);
}

class UploadFileFailure extends RepositoryFailure {
  final OdinFailureReason odinFailureReason;

  UploadFileFailure({
    int? statusCode,
    String? message,
    this.odinFailureReason = OdinFailureReason.unknown,
  }) : super(statusCode: statusCode, message: message);
}

class UploadFileSuccess extends RepositorySuccess {
  UploadFileSuccess({
    String? message,
  }) : super(message: message);
}

class FetchFilesMetadataFailure extends RepositoryFailure {
  final OdinFailureReason odinFailureReason;

  FetchFilesMetadataFailure({
    int? statusCode,
    String? message,
    this.odinFailureReason = OdinFailureReason.unknown,
  }) : super(statusCode: statusCode, message: message);
}

class FetchFilesMetadataSuccess extends RepositorySuccess {
  final FilesMetadata filesMetadata;

  FetchFilesMetadataSuccess({
    String? message,
    required this.filesMetadata,
  }) : super(message: message);
}

class FetchConfigFailure extends RepositoryFailure {
  final OdinFailureReason odinFailureReason;

  FetchConfigFailure({
    int? statusCode,
    String? message,
    this.odinFailureReason = OdinFailureReason.unknown,
  }) : super(statusCode: statusCode, message: message);
}

class FetchConfigSuccess extends RepositorySuccess {
  final Config config;

  FetchConfigSuccess({
    String? message,
    required this.config,
  }) : super(message: message);
}

class DownloadFileFailure extends RepositoryFailure {
  final OdinFailureReason odinFailureReason;

  DownloadFileFailure({
    int? statusCode,
    String? message,
    this.odinFailureReason = OdinFailureReason.unknown,
  }) : super(statusCode: statusCode, message: message);
}

class DownloadFileSuccess extends RepositorySuccess {
  final File file;

  DownloadFileSuccess({
    String? message,
    required this.file,
  }) : super(message: message);
}
