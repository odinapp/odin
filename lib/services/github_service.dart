import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:odin/model/create_file.dart';
import 'package:odin/model/github_error.dart';
import 'package:odin/model/github_json.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/services/shortener_service.dart';
import 'package:odin/services/toast_service.dart';
import 'package:path/path.dart' as path;

class GithubService {
  final _toast = locator<ToastService>();
  final ShortenerService _shortenerService = locator<ShortenerService>();
  final RandomService _randomService = locator<RandomService>();
  final _env = dotenv.env;

  Future<String> uploadFileAnonymous(File file, String password) async {
    final uploadTime = DateFormat('dd-MM-yyyy hh:mm:ss').format(DateTime.now());
    final createFile = CreateFile(
      content: base64Encode(file.readAsBytesSync()),
      message: "☄️ -> '${path.basename(file.path)}' | $uploadTime",
      path: "${_randomService.getRandomString(15)}/${path.basename(file.path)}",
    );
    final response = await request(
      'PUT',
      '/repos/${_env['GITHUB_USERNAME']}/${_env['GITHUB_REPO_NAME']}/contents/${createFile.path}',
      body: GitHubJson.encode(createFile),
    );
    if (response.statusCode == 403) {
      _toast.showToast(
        Platform.isIOS || Platform.isMacOS
            ? CupertinoIcons.multiply
            : Icons.close,
        "API rate limit exceeded",
      );
    } else {
      final _fileCode = await _shortenerService.getFileCode(
          jsonDecode(response.body)["content"]["download_url"] ?? '', password);
      if (Platform.isMacOS || Platform.isWindows) {
        return _fileCode ?? '';
      }
      final dynamicLink =
          await _shortenerService.getDynamicLink(_fileCode ?? '');
      return dynamicLink;
    }
    return '';
  }

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    dynamic body,
    int? statusCode,
    void Function(http.Response response)? fail,
    String? preview,
  }) async {
    http.Client client = http.Client();
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

    final request = http.Request(method, Uri.parse(url.toString()));
    request.headers.addAll(headers);
    if (body != null) {
      if (body is List<int>) {
        request.bodyBytes = body;
      } else {
        request.body = body.toString();
      }
    }

    final streamedResponse = await client.send(request);

    final response = await http.Response.fromStream(streamedResponse);

    if (statusCode != null && statusCode != response.statusCode) {
      if (fail != null) {
        fail(response);
      }
      handleStatusCode(response);
    } else {
      return response;
    }

    throw const UnknownError();
  }

  void handleStatusCode(http.Response response) {
    String? message;
    List<Map<String, String>>? errors;
    if (response.headers['content-type']!.contains('application/json')) {
      final json = jsonDecode(response.body);
      message = json['message'];
      if (json['errors'] != null) {
        try {
          errors = List<Map<String, String>>.from(json['errors']);
        } catch (_) {
          errors = [
            {'code': json['errors'].toString()}
          ];
        }
      }
    }
    switch (response.statusCode) {
      case 404:
        throw const NotFound('Requested Resource was Not Found');
      case 401:
        throw const AccessForbidden();
      case 400:
        if (message == 'Problems parsing JSON') {
          throw InvalidJSON(message);
        } else if (message == 'Body should be a JSON Hash') {
          throw InvalidJSON(message);
        } else {
          throw const BadRequest();
        }
      case 422:
        final buff = StringBuffer();
        buff.writeln();
        buff.writeln('  Message: $message');
        if (errors != null) {
          buff.writeln('  Errors:');
          for (final error in errors) {
            final resource = error['resource'];
            final field = error['field'];
            final code = error['code'];
            buff
              ..writeln('    Resource: $resource')
              ..writeln('    Field $field')
              ..write('    Code: $code');
          }
        }
        throw ValidationFailed(buff.toString());
      case 500:
      case 502:
      case 504:
        throw ServerError(response.statusCode, message);
    }
    throw UnknownError(message);
  }

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
