import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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

    test('uploadFilesAnonymous returns 8-char token', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/v1/file/upload/');
        await request.drain<void>();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'token': 'aB3kR9mQ',
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
          encrypt: false,
        ),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result as Success<UploadFilesSuccess, UploadFilesFailure>).value;
      expect(success.token, 'aB3kR9mQ');
      expect(success.fileCode, 'aB3kR9mQ');
      expect(success.deleteToken, 'del-123');
      expect(success.encrypted, isFalse);
    });

    test('uploadFilesAnonymous encrypted still returns short token', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/v1/file/upload/');
        await request.drain<void>();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'token': 'kT8nQm7R',
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
          encrypt: true,
        ),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result as Success<UploadFilesSuccess, UploadFilesFailure>).value;
      expect(success.fileCode, 'kT8nQm7R');
      expect(success.token, 'kT8nQm7R');
      expect(success.encrypted, isTrue);
    });

    test('fetchFilesMetadata maps JSON', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/v1/file/info/');
        expect(request.uri.queryParameters['token'], 'abc12345');
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'basePath': 'abc12345',
              'totalFileSize': '128',
              'files': <Map<String, dynamic>>[
                <String, dynamic>{'path': 'foo.txt', 'size': 10},
                <String, dynamic>{'path': 'bar.txt', 'size': 20},
              ],
              'fileCount': 2,
              'isArchive': false,
            }),
          );
        await request.response.close();
      });

      final result = await repository.fetchFilesMetadata(
        request: FetchFilesMetadataRequest(token: 'abc12345'),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result
                  as Success<
                    FetchFilesMetadataSuccess,
                    FetchFilesMetadataFailure
                  >)
              .value;
      expect(success.filesMetadata.basePath, 'abc12345');
      expect(success.filesMetadata.files?.length, 2);
      expect(success.filesMetadata.files?.first.path, 'foo.txt');
      expect(success.filesMetadata.files?.first.size, 10);
    });

    test('downloadFile writes bytes from Filename header', () async {
      const payload = 'file-content';
      server.listen((HttpRequest request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/v1/file/download/');
        expect(request.uri.queryParameters['token'], 'code1234');
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
          token: 'code1234',
          savePath: outputDir.path,
        ),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result as Success<DownloadFileSuccess, DownloadFileFailure>).value;
      expect(success.file?.path, p.join(outputDir.path, 'download.txt'));
      expect(await success.file?.readAsString(), payload);
      expect(success.encrypted, isFalse);
      expect(success.extracted, isFalse);
    });

    test('downloadFile auto-extracts archive payload', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.string('docs/a.txt', 'hello'))
        ..addFile(ArchiveFile.string('docs/b.txt', 'world'));
      final zipBytes = ZipEncoder().encode(archive);

      server.listen((HttpRequest request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/v1/file/download/');
        expect(request.uri.queryParameters['token'], 'secure12');
        request.response
          ..statusCode = 200
          ..headers.add('Filename', 'files.zip')
          ..headers.add('X-Odin-Archive', 'true')
          ..headers.add('X-Odin-Encrypted', 'true')
          ..add(zipBytes);
        await request.response.close();
      });

      final outputDir = Directory(p.join(tempDir.path, 'downloads-archive'));
      await outputDir.create(recursive: true);

      final result = await repository.downloadFile(
        request: DownloadFileRequest(
          token: 'secure12',
          savePath: outputDir.path,
        ),
      );

      expect(result.isSuccess(), isTrue);
      final success =
          (result as Success<DownloadFileSuccess, DownloadFileFailure>).value;
      expect(success.extracted, isTrue);
      expect(success.encrypted, isTrue);
      final extractedDir = success.directory;
      expect(extractedDir, isNotNull);
      expect(success.extractedFiles.length, 2);

      final contentA = await File(
        p.join(extractedDir!.path, 'docs', 'a.txt'),
      ).readAsString();
      expect(contentA, 'hello');
    });
  });
}
