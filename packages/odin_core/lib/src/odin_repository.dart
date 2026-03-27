import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'crypto_container.dart';
import 'end_points.dart';
import 'environment.dart';
import 'models/files_metadata.dart';
import 'requests.dart';
import 'responses.dart';
import 'result.dart';
import 'share_token.dart';
import 'upload_preparation.dart';
import 'utils/random_service.dart';

abstract class OdinRepository {
  Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFilesAnonymous({
    required UploadFilesRequest request,
  });

  Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>>
  fetchFilesMetadata({required FetchFilesMetadataRequest request});

  Future<Result<DownloadFileSuccess, DownloadFileFailure>> downloadFile({
    required DownloadFileRequest request,
  });

  Future<Result<FetchConfigSuccess, FetchConfigFailure>> fetchConfig({
    required FetchConfigRequest request,
  });
}

class OdinRepositoryImpl implements OdinRepository {
  OdinRepositoryImpl({
    required OdinClientConfig config,
    Dio? dio,
    RandomService? randomService,
  }) : _config = config,
       _dio = dio ?? _buildDio(config, ResponseType.json),
       _randomService = randomService ?? RandomService();

  final OdinClientConfig _config;
  final Dio _dio;
  final RandomService _randomService;

  static Dio _buildDio(OdinClientConfig config, ResponseType responseType) {
    return Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        responseType: responseType,
        validateStatus: (_) => true,
        connectTimeout: config.connectTimeout,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-App-Version': config.appVersion,
          'X-Device-OS': Platform.operatingSystem,
          'X-Device-OS-Version': Platform.operatingSystemVersion,
          'Timezone': config.timezone,
        },
      ),
    );
  }

  @override
  Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFilesAnonymous({
    required UploadFilesRequest request,
  }) async {
    final hasInputPaths = request.inputPaths?.isNotEmpty == true;
    if (request.files.isEmpty && !hasInputPaths) {
      return Failure(
        UploadFilesFailure(
          message: 'No files to upload.',
          reason: OdinFailureReason.invalidRequest,
        ),
      );
    }

    PreparedUpload? prepared;
    EncryptedUploadArtifact? encryptedArtifact;

    try {
      final candidateInputs =
          request.inputPaths ??
          request.files.map((file) => file.path).toList(growable: false);
      prepared = await prepareUploadInputs(
        inputPaths: candidateInputs,
        zipIfMultiple: true,
      );

      final filesToUpload = <File>[...prepared.filesToUpload];
      var totalFileSize = prepared.totalFileSize;
      var encrypted = false;

      if (request.encrypt) {
        encryptedArtifact = await encryptUploadFile(
          sourceFile: prepared.filesToUpload.first,
          zipped: prepared.usedCombinedZip,
          outputFileName: prepared.downloadFileName,
          originalFiles: prepared.originalFiles
              .map((entry) => entry.toJson())
              .toList(growable: false),
          originalTotalFileSize: prepared.originalTotalFileSize,
          tempDirectory: Directory.systemTemp,
        );
        filesToUpload
          ..clear()
          ..add(encryptedArtifact.file);
        totalFileSize = await encryptedArtifact.file.length();
        encrypted = true;
      }

      final formData = FormData();
      for (final file in filesToUpload) {
        final uploadName = encrypted
            ? '${_randomService.getRandomString(12)}.odin'
            : p.basename(file.path);
        formData.files.add(
          MapEntry<String, MultipartFile>(
            'file',
            await MultipartFile.fromFile(file.path, filename: uploadName),
          ),
        );
      }

      formData.fields
        ..add(
          MapEntry<String, String>(
            'directoryName',
            _randomService.getRandomString(10),
          ),
        )
        ..add(
          MapEntry<String, String>('totalFileSize', totalFileSize.toString()),
        );
      if (encryptedArtifact != null) {
        formData.fields
          ..add(
            MapEntry<String, String>(
              'manifestPreview',
              encryptedArtifact.manifestPreviewJson,
            ),
          )
          ..add(
            MapEntry<String, String>(
              'encryptionKey',
              _encodeBase64UrlNoPadding(encryptedArtifact.key),
            ),
          )
          ..add(
            MapEntry<String, String>(
              'fileCount',
              prepared.originalFiles.length.toString(),
            ),
          )
          ..add(
            MapEntry<String, String>(
              'originalTotalFileSize',
              prepared.originalTotalFileSize.toString(),
            ),
          )
          ..add(
            MapEntry<String, String>(
              'isArchive',
              prepared.usedCombinedZip.toString(),
            ),
          );
      }

      final response = await _dio.post<dynamic>(
        OdinEndPoint.uploadFiles,
        data: formData,
        cancelToken: request.cancelToken,
        onSendProgress: request.onSendProgress,
      );

      if (response.statusCode.isSuccess) {
        final data = (response.data is Map)
            ? (response.data as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final shareToken = data['token']?.toString() ?? '';
        final fileCode = parseShareToken(shareToken).fileCode;

        return Success(
          UploadFilesSuccess(
            token: shareToken,
            fileCode: fileCode,
            deleteToken: data['deleteToken'] as String?,
            encrypted: request.encrypt,
          ),
        );
      }

      final data = response.data;
      final message = data is Map
          ? (data['error']?.toString() ?? 'Upload failed')
          : (data?.toString() ?? 'Upload failed');
      return Failure(
        UploadFilesFailure(
          statusCode: response.statusCode,
          message: message,
          data: data,
        ),
      );
    } on DioException catch (e) {
      return Failure(
        UploadFilesFailure(
          statusCode: e.response?.statusCode,
          message: e.response?.toString() ?? e.message,
          data: e.response?.data,
        ),
      );
    } catch (e) {
      return Failure(UploadFilesFailure(message: e.toString()));
    } finally {
      await encryptedArtifact?.cleanup();
      await prepared?.cleanupTempArtifacts();
    }
  }

  @override
  Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>>
  fetchFilesMetadata({required FetchFilesMetadataRequest request}) async {
    final ParsedShareToken token;
    try {
      token = parseShareToken(request.token);
    } on FormatException catch (e) {
      return Failure(
        FetchFilesMetadataFailure(
          message: e.message,
          reason: OdinFailureReason.invalidRequest,
        ),
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        OdinEndPoint.fetchFilesMetadata,
        queryParameters: <String, dynamic>{'token': token.fileCode},
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
      );

      if (response.statusCode.isSuccess) {
        final data = (response.data is Map)
            ? (response.data as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return Success(
          FetchFilesMetadataSuccess(
            filesMetadata: FilesMetadata.fromJson(data),
          ),
        );
      }

      final data = response.data;
      final message = data is Map
          ? (data['error']?.toString() ?? 'Token not found or expired')
          : (data?.toString() ?? 'Token not found or expired');
      return Failure(
        FetchFilesMetadataFailure(
          statusCode: response.statusCode,
          message: message,
          data: data,
        ),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map
          ? (data['error']?.toString() ?? 'Token not found or expired')
          : (data?.toString() ?? 'Token not found or expired');
      return Failure(
        FetchFilesMetadataFailure(
          statusCode: e.response?.statusCode,
          message: message,
          data: data,
        ),
      );
    } catch (_) {
      return Failure(
        FetchFilesMetadataFailure(message: 'Something went wrong. Try again.'),
      );
    }
  }

  @override
  Future<Result<DownloadFileSuccess, DownloadFileFailure>> downloadFile({
    required DownloadFileRequest request,
  }) async {
    final ParsedShareToken token;
    try {
      token = parseShareToken(request.token);
    } on FormatException catch (e) {
      return Failure(
        DownloadFileFailure(
          message: e.message,
          reason: OdinFailureReason.invalidRequest,
        ),
      );
    }

    final downloadDio = _buildDio(_config, ResponseType.bytes);
    try {
      final response = await downloadDio.get<dynamic>(
        OdinEndPoint.downloadFiles,
        queryParameters: <String, dynamic>{'token': token.fileCode},
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
      );

      if (response.statusCode.isSuccess) {
        final bytes = (response.data as List<dynamic>).cast<int>();
        final encryptedPayload = isEncryptedContainer(bytes);

        if (request.requireEncrypted && !encryptedPayload) {
          return Failure(
            DownloadFileFailure(
              message:
                  'Server returned plaintext data, but encrypted payload is required.',
              reason: OdinFailureReason.encryptedPayloadRequired,
            ),
          );
        }

        final fileName = _safeFileName(
          response.headers.value('Filename'),
          fallback: 'download.bin',
        );
        final isArchive = response.headers.value('X-Odin-Archive') == 'true';
        final wasEncrypted =
            response.headers.value('X-Odin-Encrypted') == 'true';

        if (request.autoExtractArchives && isArchive) {
          try {
            final extracted = await _extractArchive(
              archiveBytes: bytes,
              saveRootPath: request.savePath,
              tokenCode: token.fileCode,
              archiveName: fileName,
            );
            return Success(
              DownloadFileSuccess(
                directory: extracted.$1,
                extractedFiles: extracted.$2,
                encrypted: wasEncrypted,
              ),
            );
          } on ArchiveException catch (e) {
            return Failure(
              DownloadFileFailure(
                message: 'Failed to extract archive: ${e.message}',
                reason: OdinFailureReason.decryptionFailed,
              ),
            );
          }
        }

        final output = File(p.join(request.savePath, fileName));
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes, flush: true);
        return Success(
          DownloadFileSuccess(
            file: output,
            encrypted: wasEncrypted || encryptedPayload,
          ),
        );
      }

      return Failure(
        DownloadFileFailure(
          statusCode: response.statusCode,
          message: response.data?.toString(),
          data: response.data,
        ),
      );
    } on DioException catch (e) {
      return Failure(
        DownloadFileFailure(
          statusCode: e.response?.statusCode,
          message: e.response?.toString() ?? e.message,
          data: e.response?.data,
        ),
      );
    } catch (e) {
      return Failure(DownloadFileFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FetchConfigSuccess, FetchConfigFailure>> fetchConfig({
    required FetchConfigRequest request,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        OdinEndPoint.config,
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
      );

      if (response.statusCode.isSuccess) {
        final data = (response.data is Map)
            ? (response.data as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return Success(FetchConfigSuccess(config: data));
      }

      return Failure(
        FetchConfigFailure(
          statusCode: response.statusCode,
          message: response.data?.toString(),
          data: response.data,
        ),
      );
    } on DioException catch (e) {
      return Failure(
        FetchConfigFailure(
          statusCode: e.response?.statusCode,
          message: e.response?.toString() ?? e.message,
          data: e.response?.data,
        ),
      );
    } catch (e) {
      return Failure(FetchConfigFailure(message: e.toString()));
    }
  }
}

Future<(Directory, List<File>)> _extractArchive({
  required List<int> archiveBytes,
  required String saveRootPath,
  required String tokenCode,
  required String archiveName,
}) async {
  final safeDirName = _safeExtractDirectoryName(tokenCode, archiveName);
  final outDir = Directory(p.join(saveRootPath, safeDirName));
  await outDir.create(recursive: true);

  final archive = ZipDecoder().decodeBytes(archiveBytes, verify: true);
  final files = <File>[];
  for (final entry in archive) {
    final name = entry.name.replaceAll('\\', '/');
    if (name.isEmpty || name.endsWith('/')) {
      continue;
    }
    final rel = p.normalize(name).replaceFirst(RegExp(r'^(\.\.[/\\])+'), '');
    final outputPath = p.join(outDir.path, rel);
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(entry.content, flush: true);
    files.add(outputFile);
  }
  return (outDir, files);
}

String _safeFileName(String? raw, {required String fallback}) {
  final name = (raw ?? '').trim();
  if (name.isEmpty) return fallback;
  return p.basename(name);
}

String _safeExtractDirectoryName(String tokenCode, String archiveName) {
  final stem = p.basenameWithoutExtension(archiveName).trim();
  final raw = stem.isEmpty ? 'files_$tokenCode' : stem;
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return cleaned.isEmpty ? 'files_$tokenCode' : cleaned;
}

String _encodeBase64UrlNoPadding(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}
