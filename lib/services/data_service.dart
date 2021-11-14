import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:github/github.dart';
import 'package:intl/intl.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/services/shortner_service.dart';
import 'package:path/path.dart' as path;

class DataService {
  final ShortnerService _shortnerService = locator<ShortnerService>();
  final RandomService _randomService = locator<RandomService>();
  final _env = dotenv.env;
  final _gh =
      GitHub(auth: Authentication.withToken(dotenv.env['GITHUB_TOKEN']));

  Future<String> uploadFileAnonymous(File file) async {
    final uploadTime = DateFormat('dd-MM-yyyy hh:mm:ss').format(DateTime.now());
    final _ghFile = await _gh.repositories.createFile(
      RepositorySlug(
          _env['GITHUB_USERNAME'] ?? '', _env['GITHUB_REPO_NAME'] ?? ''),
      CreateFile(
        content: base64Encode(file.readAsBytesSync()),
        message: "☄️ -> '${path.basename(file.path)}' | $uploadTime",
        path:
            "${_randomService.getRandomString(15)}/${path.basename(file.path)}",
      ),
    );
    final _downloadLink = await _shortnerService.shortUrl(
        url: _ghFile.content?.downloadUrl ?? '');
    return _downloadLink ?? '';
  }
}
