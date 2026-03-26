import 'dart:io';

import 'models/files_metadata.dart';
import 'result.dart';

enum OdinFailureReason { unknown, invalidRequest }

class UploadFilesSuccess extends RepositorySuccess {
  UploadFilesSuccess({required this.token, this.deleteToken, super.message});

  final String token;
  final String? deleteToken;
}

class UploadFilesFailure extends RepositoryFailure {
  UploadFilesFailure({
    super.statusCode,
    super.message,
    super.data,
    this.reason = OdinFailureReason.unknown,
  });

  final OdinFailureReason reason;
}

class FetchFilesMetadataSuccess extends RepositorySuccess {
  FetchFilesMetadataSuccess({required this.filesMetadata, super.message});

  final FilesMetadata filesMetadata;
}

class FetchFilesMetadataFailure extends RepositoryFailure {
  FetchFilesMetadataFailure({
    super.statusCode,
    super.message,
    super.data,
    this.reason = OdinFailureReason.unknown,
  });

  final OdinFailureReason reason;
}

class DownloadFileSuccess extends RepositorySuccess {
  DownloadFileSuccess({required this.file, super.message});

  final File file;
}

class DownloadFileFailure extends RepositoryFailure {
  DownloadFileFailure({
    super.statusCode,
    super.message,
    super.data,
    this.reason = OdinFailureReason.unknown,
  });

  final OdinFailureReason reason;
}

class FetchConfigSuccess extends RepositorySuccess {
  FetchConfigSuccess({required this.config, super.message});

  final Map<String, dynamic> config;
}

class FetchConfigFailure extends RepositoryFailure {
  FetchConfigFailure({
    super.statusCode,
    super.message,
    super.data,
    this.reason = OdinFailureReason.unknown,
  });

  final OdinFailureReason reason;
}
