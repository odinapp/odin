import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:odin/model/create_file.dart';
import 'package:odin/model/github_error.dart';
import 'package:odin/model/github_json.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/services/shortner_service.dart';
// import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

typedef OnUploadProgressCallback = void Function(int sentBytes, int totalBytes);

class GithubService {
  final ShortnerService _shortnerService = locator<ShortnerService>();
  final RandomService _randomService = locator<RandomService>();
  final _env = dotenv.env;

  static HttpClient getHttpClient() {
    HttpClient httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

    return httpClient;
  }

  Future<String> uploadFileAnonymous(File file) async {
    final uploadTime = DateFormat('dd-MM-yyyy hh:mm:ss').format(DateTime.now());
    final createFile = CreateFile(
      content: base64Encode(file.readAsBytesSync()),
      message: "☄️ -> '${path.basename(file.path)}' | $uploadTime",
      path: "${_randomService.getRandomString(15)}/${path.basename(file.path)}",
    );
    final bodyString = GitHubJson.encode(createFile);
    final Directory tempFolder = await getTemporaryDirectory();
    final tempFileSavePath = tempFolder.path;
    final String tempFilePath = path.join(
        tempFileSavePath, "${_randomService.getRandomString(15)}.txt");
    final File textFile = File(tempFilePath);
    textFile.writeAsStringSync(bodyString);
    final createFileSync = CreateFile(
      message: "☄️ -> '${path.basename(file.path)}' | $uploadTime",
      path: "${_randomService.getRandomString(15)}/${path.basename(file.path)}",
    );
    final response = await request(
      'PUT',
      '/repos/${_env['GITHUB_USERNAME']}/${_env['GITHUB_REPO_NAME']}/contents/${createFile.path}',
      body: GitHubJson.encode(createFile),
      totalByteLength: textFile.lengthSync(),
      file: textFile,
      // fileStream: file.openRead().cast<List<int>>().asyncMap(
      //   (event) {
      //     createFileSync.content = base64Encode(event);
      //     return createFileSync;
      //   },
      // ),
      onUploadProgress: (sentBytes, totalBytes) {
        logger.d(
            'Uploaded ${((sentBytes / totalBytes) * 100).toStringAsFixed(2)}%');
      },
    );

    // response.listen((event) {
    //   logger.i(event);
    // });
    // response.

    // final _downloadLink = await _shortnerService.shortUrl(
    //     url: jsonDecode(response.)["content"]["download_url"] ?? '');
    // return _downloadLink ?? '';
    return "sdfdg";
  }

  Future<HttpClientResponse> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    dynamic body,
    File? file,
    int? statusCode,
    void Function(HttpClientResponse response)? fail,
    String? preview,
    OnUploadProgressCallback? onUploadProgress,
    int? totalByteLength,
  }) async {
    HttpClient client = getHttpClient();
    headers ??= <String, String>{};

    if (preview != null) {
      headers['Accept'] = preview;
    }

    headers.putIfAbsent('Authorization', () => 'token ${_env['GITHUB_TOKEN']}');

    if (method == 'PUT' && body == null) {
      headers.putIfAbsent('Content-Length', () => '0');
    }

    var queryString = '';

    if (params != null) {
      queryString = buildQueryString(params);
    }

    final url = StringBuffer();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      url.write(path);
      url.write(queryString);
    } else {
      url.write('https://api.github.com');
      if (!path.startsWith('/')) {
        url.write('/');
      }
      url.write(path);
      url.write(queryString);
    }
    final HttpClientRequest request =
        await client.postUrl(Uri.parse(url.toString()));
    // final request = http.Request(method, Uri.parse(url.toString()));
    headers.forEach((key, value) {
      request.headers.add(key, value);
    });
    // request.headers.addAll(headers);
    // if (body != null) {
    //   if (body is List<int>) {
    //     request.bodyBytes = body;
    //   } else {
    //     request.body = body.toString();
    //   }
    // }
    final fileStream = file!.openRead();

    int byteCount = 0;
    Stream<List<int>> streamUpload = fileStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          byteCount += data.length;

          if (onUploadProgress != null) {
            onUploadProgress(byteCount, totalByteLength!);
            // CALL STATUS CALLBACK;
          }

          sink.add(body);
        },
        handleError: (error, stack, sink) {
          logger.e(error.toString());
        },
        handleDone: (sink) {
          sink.close();
          // UPLOAD DONE;
        },
      ),
    );

    await request.addStream(streamUpload);
    final response = await request.close();
    String reply = await response.transform(utf8.decoder).join();
    logger.e(reply);
    // final streamedResponse = await client.send(request);

    // final response = await http.Response.fromStream(streamedResponse);

    if (statusCode != null && statusCode != response.statusCode) {
      if (fail != null) {
        fail(response);
      }
      // handleStatusCode(response);
    } else {
      return response;
    }

    throw const UnknownError();
  }

  // void handleStatusCode(HttpClientResponse response) {
  //   String? message;
  //   List<Map<String, String>>? errors;
  //   if (response.headers['content-type']!.contains('application/json')) {
  //     final json = jsonDecode(response.body);
  //     message = json['message'];
  //     if (json['errors'] != null) {
  //       try {
  //         errors = List<Map<String, String>>.from(json['errors']);
  //       } catch (_) {
  //         errors = [
  //           {'code': json['errors'].toString()}
  //         ];
  //       }
  //     }
  //   }
  //   switch (response.statusCode) {
  //     case 404:
  //       throw const NotFound('Requested Resource was Not Found');
  //     case 401:
  //       throw const AccessForbidden();
  //     case 400:
  //       if (message == 'Problems parsing JSON') {
  //         throw InvalidJSON(message);
  //       } else if (message == 'Body should be a JSON Hash') {
  //         throw InvalidJSON(message);
  //       } else {
  //         throw const BadRequest();
  //       }
  //     case 422:
  //       final buff = StringBuffer();
  //       buff.writeln();
  //       buff.writeln('  Message: $message');
  //       if (errors != null) {
  //         buff.writeln('  Errors:');
  //         for (final error in errors) {
  //           final resource = error['resource'];
  //           final field = error['field'];
  //           final code = error['code'];
  //           buff
  //             ..writeln('    Resource: $resource')
  //             ..writeln('    Field $field')
  //             ..write('    Code: $code');
  //         }
  //       }
  //       throw ValidationFailed(buff.toString());
  //     case 500:
  //     case 502:
  //     case 504:
  //       throw ServerError(response.statusCode, message);
  //   }
  //   throw UnknownError(message);
  // }

  String buildQueryString(Map<String, dynamic> params) {
    final queryString = StringBuffer();

    if (params.isNotEmpty && !params.values.every((value) => value == null)) {
      queryString.write('?');
    }

    var i = 0;
    for (final key in params.keys) {
      i++;
      if (params[key] == null) {
        continue;
      }
      queryString.write('$key=${Uri.encodeComponent(params[key].toString())}');
      if (i != params.keys.length) {
        queryString.write('&');
      }
    }
    return queryString.toString();
  }
}
