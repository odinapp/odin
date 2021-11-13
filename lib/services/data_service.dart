import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:github/github.dart';
import 'package:path/path.dart' as path;

class DataService {
  final _env = dotenv.env;
  final _gh =
      GitHub(auth: Authentication.withToken(dotenv.env['GITHUB_TOKEN']));

  Future<void> uploadFileAnonymous(File file) async {
    await _gh.repositories.createFile(
      RepositorySlug(
          _env['GITHUB_USERNAME'] ?? '', _env['GITHUB_REPO_NAME'] ?? ''),
      CreateFile(
        branch: _env['GITHUB_BRANCH_NAME'],
        committer: CommitUser(
            _env['GITHUB_COMMIT_USER_NAME'], _env['GITHUB_COMMIT_USER_EMAIL']),
        content: base64Encode(file.readAsBytesSync()),
        message: "☄️ -> '${path.basename(file.path)}'",
        path: path.basename(file.path),
      ),
    );
  }
}
