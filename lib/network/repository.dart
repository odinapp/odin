import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/model/config.dart';
import 'package:odin/model/files_metadata.dart';
import 'package:odin/network/repository_impl.dart';
import 'package:odin/utilities/networking.dart';

part './requests.dart';
part './responses.dart';

abstract class OdinRepository extends Repository {
  factory OdinRepository() {
    return OdinRepositoryImpl();
  }

  Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFilesAnonymous({
    required UploadFilesRequest request,
  });

  Future<Result<UploadFileSuccess, UploadFileFailure>> uploadFileAnonymous({
    required UploadFileRequest request,
  });

  Future<Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure>> fetchFilesMetadata({
    required FetchFilesMetadataRequest request,
  });

  Future<Result<FetchConfigSuccess, FetchConfigFailure>> fetchConfig({
    required FetchConfigRequest request,
  });

  Future<Result<DownloadFileSuccess, DownloadFileFailure>> downloadFile({
    required DownloadFileRequest request,
  });
}
