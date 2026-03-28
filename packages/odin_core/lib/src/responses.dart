import 'dart:io';

import 'models/files_metadata.dart';
import 'result.dart';

enum OdinFailureReason {
  unknown,
  invalidRequest,
  missingDecryptionKey,
  invalidDecryptionKey,
  decryptionFailed,
  encryptedPayloadRequired,
}

class UploadFilesSuccess extends RepositorySuccess {
  UploadFilesSuccess({
    required this.token,
    required this.fileCode,
    this.deleteToken,
    this.encrypted = false,
    super.message,
  });

  /// Share token for users (8-character code).
  final String token;

  /// Backend file code used by API calls.
  final String fileCode;
  final String? deleteToken;
  final bool encrypted;
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
  DownloadFileSuccess({
    this.file,
    this.directory,
    this.extractedFiles = const <File>[],
    this.encrypted = false,
    super.message,
  }) : assert(
         file != null || directory != null,
         'Either file or directory must be provided.',
       );

  final File? file;
  final Directory? directory;
  final List<File> extractedFiles;
  final bool encrypted;

  bool get extracted => directory != null;

  String get outputPath => file?.path ?? directory!.path;
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
