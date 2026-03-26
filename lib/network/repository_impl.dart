import 'dart:io';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:odin/amenities/app_info/amenity.dart';
import 'package:odin/model/config.dart';
import 'package:odin/model/files_metadata.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/utilities/networking.dart';
import 'package:odin_core/odin_core.dart' as core;

class OdinRepositoryImpl implements OdinRepository {
  Future<core.OdinRepository> _createCoreRepository() async {
    final envService = locator<EnvironmentService>();
    final timezone = (await FlutterTimezone.getLocalTimezone()).identifier;

    final env = core.OdinEnvironment(
      apiUrl: envService.environment.API_URL,
      apiVersion: envService.environment.API_VERSION,
      successfulStatusCode:
          int.tryParse(envService.environment.SUCCESSFUL_STATUS_CODE) ?? 200,
    );
    final config = core.OdinClientConfig(
      environment: env,
      appVersion: AppInfoAmenity.instance.info.version,
      timezone: timezone,
    );
    return core.OdinRepositoryImpl(config: config);
  }

  @override
  Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFilesAnonymous({
    required UploadFilesRequest request,
  }) async {
    final repo = await _createCoreRepository();
    final result = await repo.uploadFilesAnonymous(
      request: core.UploadFilesRequest(
        files: request.files,
        totalFileSize: request.totalFileSize,
        onSendProgress: request.onSendProgress,
        cancelToken: request.cancelToken,
      ),
    );

    return result.resolve(
      (successValue) => Success(
        UploadFilesSuccess(
          token: successValue.token,
          deleteToken: successValue.deleteToken,
          message: successValue.message,
        ),
      ),
      (failureValue) => Failure(
        UploadFilesFailure(
          statusCode: failureValue.statusCode,
          message: failureValue.message,
        ),
      ),
    );
  }

  @override
  Future<Result<UploadFileSuccess, UploadFileFailure>> uploadFileAnonymous({
    required UploadFileRequest request,
  }) async {
    final repo = await _createCoreRepository();
    final result = await repo.uploadFilesAnonymous(
      request: core.UploadFilesRequest(
        files: <File>[request.file],
        totalFileSize: request.fileSize,
        onSendProgress: request.onSendProgress,
        cancelToken: request.cancelToken,
      ),
    );

    return result.resolve(
      (_) => Success(UploadFileSuccess()),
      (failureValue) => Failure(
        UploadFileFailure(
          statusCode: failureValue.statusCode,
          message: failureValue.message,
        ),
      ),
    );
  }

  @override
  Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>>
  fetchFilesMetadata({required FetchFilesMetadataRequest request}) async {
    final repo = await _createCoreRepository();
    final result = await repo.fetchFilesMetadata(
      request: core.FetchFilesMetadataRequest(
        token: request.token,
        onReceiveProgress: request.onReceiveProgress,
        cancelToken: request.cancelToken,
      ),
    );

    return result.resolve(
      (successValue) => Success(
        FetchFilesMetadataSuccess(
          filesMetadata: FilesMetadata.fromJson(
            successValue.filesMetadata.toJson(),
          ),
          message: successValue.message,
        ),
      ),
      (failureValue) => Failure(
        FetchFilesMetadataFailure(
          statusCode: failureValue.statusCode,
          message: failureValue.message,
        ),
      ),
    );
  }

  @override
  Future<Result<FetchConfigSuccess, FetchConfigFailure>> fetchConfig({
    required FetchConfigRequest request,
  }) async {
    final repo = await _createCoreRepository();
    final result = await repo.fetchConfig(
      request: core.FetchConfigRequest(
        onReceiveProgress: request.onReceiveProgress,
        cancelToken: request.cancelToken,
      ),
    );

    return result.resolve(
      (successValue) => Success(
        FetchConfigSuccess(
          config: Config.fromJson(successValue.config),
          message: successValue.message,
        ),
      ),
      (failureValue) => Failure(
        FetchConfigFailure(
          statusCode: failureValue.statusCode,
          message: failureValue.message,
        ),
      ),
    );
  }

  @override
  Future<Result<DownloadFileSuccess, DownloadFileFailure>> downloadFile({
    required DownloadFileRequest request,
  }) async {
    final repo = await _createCoreRepository();
    final result = await repo.downloadFile(
      request: core.DownloadFileRequest(
        token: request.token,
        savePath: request.savePath,
        onReceiveProgress: request.onReceiveProgress,
        cancelToken: request.cancelToken,
      ),
    );

    return result.resolve(
      (successValue) => Success(
        DownloadFileSuccess(
          file: successValue.file,
          message: successValue.message,
        ),
      ),
      (failureValue) => Failure(
        DownloadFileFailure(
          statusCode: failureValue.statusCode,
          message: failureValue.message,
        ),
      ),
    );
  }
}
