import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:odin/services/download_service.dart';
import 'package:odin/services/encryption_service.dart';
import 'package:odin/services/github_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/shortener_service.dart';
import 'package:odin/services/zip_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  final _shortenerService = locator<ShortenerService>();
  final _githubService = locator<GithubService>();
  final _zipService = locator<ZipService>();
  final _encrytionService = locator<EncryptionService>();
  final _downloadService = locator<DownloadService>();
  bool uploading = false;
  bool downloading = false;
  bool processing = false;
  String? fileLink;
  String zipfileName = '';

  Future<void> getLinkFromFilePicker() async {
    fileLink = null;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    final String? _path;
    if (result != null) {
      zipfileName = '';
      uploading = true;
      processing = true;
      List<File> files = result.paths.map((path) => File(path!)).toList();
      File zippedFile;
      if (files.length > 1) {
        zippedFile = await _zipService.zipFile(fileToZips: files);
      } else {
        final Directory cacheDir = await getTemporaryDirectory();
        zippedFile = files[0];
        zippedFile =
            zippedFile.copySync(join(cacheDir.path, basename(files[0].path)));
      }
      final encryptedFileDetails =
          await _encrytionService.encryptFile(zippedFile);
      zipfileName = basename(zippedFile.path);
      processing = false;
      _path = await _githubService.uploadFileAnonymous(
          encryptedFileDetails['file'], encryptedFileDetails['password']);
      uploading = false;
    } else {
      // User canceled the picker
      _path = null;
    }
    fileLink = _path;
  }

  Future<void> getLinkFromDroppedFiles(List<Uri> urls) async {
    fileLink = null;
    final String? _path;
    if (urls.isNotEmpty) {
      zipfileName = '';
      uploading = true;
      processing = true;
      final List<File> files = urls.map((e) => File(e.toFilePath())).toList();
      File zippedFile;
      if (files.length > 1) {
        zippedFile = await _zipService.zipFile(fileToZips: files);
      } else {
        final Directory cacheDir = await getTemporaryDirectory();
        zippedFile = files[0];
        zippedFile =
            zippedFile.copySync(join(cacheDir.path, basename(files[0].path)));
      }
      final encryptedFileDetails =
          await _encrytionService.encryptFile(zippedFile);
      zipfileName = basename(zippedFile.path);
      processing = false;
      _path = await _githubService.uploadFileAnonymous(
          encryptedFileDetails['file'], encryptedFileDetails['password']);
      uploading = false;
    } else {
      _path = null;
    }
    fileLink = _path;
  }

  Future<String> getFileFromToken(String token) async {
    downloading = true;
    processing = true;
    final password = token.substring(token.length - 16);
    final fileCode = token.replaceAll(password, "");
    final fileLink = _shortenerService.getShortUrlFromFileCode(fileCode);
    processing = false;
    final file = await _downloadService.downloadFile(fileLink);
    processing = true;
    final decryptedFile = await _encrytionService.decryptFile(file, password);
    logger.d("decryptedFile path : ${decryptedFile.path}");
    if (decryptedFile.path.endsWith('.zip')) {
      final unzippedFilePath = await _zipService.unzipFile(decryptedFile);
      logger.d("unzippedFile path : $unzippedFilePath");
      processing = false;
      downloading = false;
      return unzippedFilePath;
    } else {
      processing = false;
      downloading = false;
      return decryptedFile.parent.path;
    }
  }
}
