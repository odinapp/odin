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
