import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'end_points.dart';
import 'environment.dart';
import 'models/files_metadata.dart';
import 'requests.dart';
import 'responses.dart';
import 'result.dart';
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
    try {
      final formData = FormData();
      for (final file in request.files) {
        formData.files.add(
          MapEntry<String, MultipartFile>(
            'file',
            await MultipartFile.fromFile(
              file.path,
              filename: p.basename(file.path),
            ),
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
          MapEntry<String, String>(
            'totalFileSize',
            request.totalFileSize.toString(),
          ),
        );

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
        final rawToken = data['token'] as String? ?? '';
        final uri = Uri.tryParse(rawToken);
        final token = (uri != null && uri.pathSegments.isNotEmpty)
            ? uri.pathSegments.lastWhere(
                (segment) => segment.isNotEmpty,
                orElse: () => rawToken,
              )
            : rawToken;
        return Success(
          UploadFilesSuccess(
            token: token,
            deleteToken: data['deleteToken'] as String?,
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
    }
  }

  @override
  Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>>
  fetchFilesMetadata({required FetchFilesMetadataRequest request}) async {
    try {
      final response = await _dio.get<dynamic>(
        OdinEndPoint.fetchFilesMetadata,
        queryParameters: <String, dynamic>{'token': request.token},
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
    final downloadDio = _buildDio(_config, ResponseType.bytes);
    try {
      final response = await downloadDio.get<dynamic>(
        OdinEndPoint.downloadFiles,
        queryParameters: <String, dynamic>{'token': request.token},
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
      );

      if (response.statusCode.isSuccess) {
        final fileName =
            response.headers.value('Filename') ?? 'defaultFile.txt';
        final output = File(p.join(request.savePath, fileName));
        await output.parent.create(recursive: true);
        final bytes = (response.data as List<dynamic>).cast<int>();
        await output.writeAsBytes(bytes, flush: true);
        return Success(DownloadFileSuccess(file: output));
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
