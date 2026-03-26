import 'dart:convert';
import 'dart:io';

import 'package:odin_core/odin_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('OdinRepositoryImpl', () {
    late HttpServer server;
    late Directory tempDir;
    late Uri baseUri;
    late OdinRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('odin_core_test');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUri = Uri.parse('http://${server.address.address}:${server.port}/');

      final config = OdinClientConfig(
        environment: OdinEnvironment(
          apiUrl: baseUri.toString(),
          apiVersion: 'v1',
          successfulStatusCode: 200,
        ),
        appVersion: 'test',
        timezone: 'UTC',
      );
      repository = OdinRepositoryImpl(config: config);
    });

    tearDown(() async {
      await server.close(force: true);
      await tempDir.delete(recursive: true);
    });

    test('uploadFilesAnonymous parses token code from URL', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/v1/file/upload/');
        await request.drain<void>();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'token': 'https://getodin.com/d/aB3kR9mQ',
              'deleteToken': 'del-123',
            }),
          );
        await request.response.close();
      });

      final uploadFile = File(p.join(tempDir.path, 'a.txt'));
      await uploadFile.writeAsString('hello');

      final result = await repository.uploadFilesAnonymous(
        request: UploadFilesRequest(
          files: <File>[uploadFile],
          totalFileSize: await uploadFile.length(),
        ),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result as Success<UploadFilesSuccess, UploadFilesFailure>).value;
      expect(success.token, 'aB3kR9mQ');
      expect(success.deleteToken, 'del-123');
    });

    test('fetchFilesMetadata maps JSON', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/v1/file/info/');
        expect(request.uri.queryParameters['token'], 'abc123');
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'basePath': 'abc123',
              'totalFileSize': '128',
              'files': <Map<String, String>>[
                <String, String>{'path': 'foo.txt'},
                <String, String>{'path': 'bar.txt'},
              ],
            }),
          );
        await request.response.close();
      });

      final result = await repository.fetchFilesMetadata(
        request: FetchFilesMetadataRequest(token: 'abc123'),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result
                  as Success<
                    FetchFilesMetadataSuccess,
                    FetchFilesMetadataFailure
                  >)
              .value;
      expect(success.filesMetadata.basePath, 'abc123');
      expect(success.filesMetadata.files?.length, 2);
      expect(success.filesMetadata.files?.first.path, 'foo.txt');
    });

    test('downloadFile writes bytes from Filename header', () async {
      const payload = 'file-content';
      server.listen((HttpRequest request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/v1/file/download/');
        expect(request.uri.queryParameters['token'], 'code123');
        request.response
          ..statusCode = 200
          ..headers.add('Filename', 'download.txt')
          ..add(utf8.encode(payload));
        await request.response.close();
      });

      final outputDir = Directory(p.join(tempDir.path, 'downloads'));
      await outputDir.create(recursive: true);

      final result = await repository.downloadFile(
        request: DownloadFileRequest(
          token: 'code123',
          savePath: outputDir.path,
        ),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result as Success<DownloadFileSuccess, DownloadFileFailure>).value;
      expect(success.file.path, p.join(outputDir.path, 'download.txt'));
      expect(await success.file.readAsString(), payload);
    });
  });
}
