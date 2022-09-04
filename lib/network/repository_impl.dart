import 'package:dio/dio.dart';
import 'package:odin/network/networking_box/networking_box.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/utilities/networking.dart';

part './end_points.dart';

class OdinRepositoryImpl implements OdinRepository {
  static final randomService = locator<RandomService>();

  @override
  Future<Result<UploadFilesSuccess, UploadFilesFailure>> uploadFilesAnonymous({
    required UploadFilesRequest request,
  }) async {
    final client = await ONetworkingBox.unsecureClient();

    if (client != null) {
      final formData = FormData();
      var totalFileSizeInBytes = 0;
      for (var file in request.files) {
        totalFileSizeInBytes += await file.length();
        logger.d('[DioService]: fileName: ${file.path.split('/').last}');
        formData.files.addAll([
          MapEntry(
            "file",
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ),
        ]);
      }

      final directoryName = randomService.getRandomString(10);

      formData.fields.add(MapEntry("directoryName", directoryName));
      formData.fields.add(MapEntry("totalFileSize", totalFileSizeInBytes.toString()));

      final response = await client.post(
        _EndPoint.uploadFiles,
        cancelToken: request.cancelToken,
        onSendProgress: request.onSendProgress,
        data: formData,
      );
      final statusCode = response.statusCode;

      if (statusCode.isSuccess) {
        final data = response.data;
        return Success(UploadFilesSuccess());
      } else {
        return Failure(UploadFilesFailure(message: response.data));
      }
    } else {
      return Failure(UploadFilesFailure());
    }
  }

  @override
  Future<Result<UploadFileSuccess, UploadFileFailure>> uploadFileAnonymous({required UploadFileRequest request}) async {
    final client = await ONetworkingBox.unsecureClient();

    if (client != null) {
      String fileName = request.file.path.split('/').last;
      final directoryName = randomService.getRandomString(10);
      final fileSize = await request.file.length();

      final multipartFile = await MultipartFile.fromFile(request.file.path, filename: fileName);
      final requestJson = <String, dynamic>{
        'directoryName': directoryName,
        'totalFileSize': fileSize.toString(),
      };

      requestJson['media'] = multipartFile;

      logger.d('[DioService]: fileName: $fileName');
      logger.d('[DioService]: requestJson: $requestJson');
      FormData formData = FormData.fromMap(requestJson);

      final response = await client.post(
        _EndPoint.uploadFiles,
        cancelToken: request.cancelToken,
        onSendProgress: request.onSendProgress,
        data: formData,
      );
      final statusCode = response.statusCode;

      if (statusCode.isSuccess) {
        final data = response.data;
        return Success(UploadFileSuccess());
      } else {
        return Failure(UploadFileFailure());
      }
    } else {
      return Failure(UploadFileFailure());
    }
  }
}
