import 'dart:io';

// import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:odin/services/download_service.dart';
// import 'package:odin/services/encryption_service.dart';
// import 'package:odin/services/github_service.dart';
// import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
// import 'package:odin/services/shortener_service.dart';
// import 'package:odin/services/zip_service.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';

/// Result of [FileService.pickMultipleFiles].
///
/// [files] is set on success. Both [files] and [errorMessage] are null when the
/// user dismissed the dialog. [errorMessage] is set when the picker could not
/// run (e.g. Linux without zenity/kdialog/qarma).
class FilePickResult {
  const FilePickResult({this.files, this.errorMessage});

  final List<File>? files;
  final String? errorMessage;
}

Future<bool> _linuxFilePickerAvailable() async {
  const candidates = ['qarma', 'kdialog', 'zenity'];
  for (final name in candidates) {
    try {
      final result = await Process.run('which', [name]);
      if (result.exitCode != 0) continue;
      if (result.stdout.toString().trim().isEmpty) continue;
      return true;
    } on Object {
      continue;
    }
  }
  return false;
}

class FileService {
  // final _shortenerService = locator<ShortenerService>();
  // final _githubService = locator<GithubService>();
  // final _zipService = locator<ZipService>();
  // final _encrytionService = locator<EncryptionService>();
  // final _downloadService = locator<DownloadService>();
  bool uploading = false;
  bool downloading = false;
  bool processing = false;
  String? fileLink;
  String zipfileName = '';

  Future<File?> pickSingleFile() async {
    if (Platform.isLinux) {
      final ok = await _linuxFilePickerAvailable();
      if (!ok) {
        logger.w(
          'Linux file picker: install zenity, kdialog, or qarma '
          '(e.g. sudo apt install zenity).',
        );
        return null;
      }
    }
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }
      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        return null;
      }
      return File(path);
    } catch (e, st) {
      logger.e('$e', error: e, stackTrace: st);
      return null;
    }
  }

  Future<FilePickResult> pickMultipleFiles() async {
    if (Platform.isLinux) {
      final ok = await _linuxFilePickerAvailable();
      if (!ok) {
        logger.w(
          'Linux file picker: no qarma, kdialog, or zenity in PATH. '
          'Install one (e.g. sudo apt install zenity).',
        );
        return const FilePickResult(
          errorMessage:
              'Odin needs a file picker on Linux. Install zenity (or kdialog): '
              'sudo apt install zenity',
        );
      }
    }
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      if (result == null) {
        return const FilePickResult();
      }
      final files = result.files
          .where((e) => e.path != null && e.path!.isNotEmpty)
          .map((e) => File(e.path!))
          .toList();
      if (files.isEmpty) {
        return const FilePickResult();
      }
      return FilePickResult(files: files);
    } catch (e, st) {
      logger.e('$e', error: e, stackTrace: st);
      return const FilePickResult(
        errorMessage:
            'Could not open the file picker. Try again, or restart the app.',
      );
    }
  }

  // Future<void> getLinkFromFilePicker() async {
  //   fileLink = null;
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
  //   final String? path;
  //   if (result != null) {
  //     zipfileName = '';
  //     uploading = true;
  //     processing = true;
  //     List<File> files = result.paths.map((path) => File(path!)).toList();
  //     File zippedFile;
  //     if (files.length > 1) {
  //       zippedFile = await _zipService.zipFile(fileToZips: files);
  //     } else {
  //       final Directory cacheDir = await getTemporaryDirectory();
  //       zippedFile = files[0];
  //       zippedFile = zippedFile.copySync(join(cacheDir.path, basename(files[0].path)));
  //     }
  //     final encryptedFileDetails = await _encrytionService.encryptFile(zippedFile);
  //     zipfileName = basename(zippedFile.path);
  //     processing = false;
  //     path = await _githubService.uploadFileAnonymous(encryptedFileDetails.file, encryptedFileDetails.password);
  //     uploading = false;
  //   } else {
  //     // User canceled the picker
  //     path = null;
  //   }
  //   fileLink = path;
  // }

  // Future<void> getLinkFromDroppedFiles(List<XFile> xfiles) async {
  //   fileLink = null;
  //   final String? path;
  //   if (xfiles.isNotEmpty) {
  //     zipfileName = '';
  //     uploading = true;
  //     processing = true;
  //     final List<File> files = xfiles.map((e) => File(e.path)).toList();
  //     File zippedFile;
  //     if (files.length > 1) {
  //       zippedFile = await _zipService.zipFile(fileToZips: files);
  //     } else {
  //       final Directory cacheDir = await getTemporaryDirectory();
  //       zippedFile = files[0];
  //       zippedFile = zippedFile.copySync(join(cacheDir.path, basename(files[0].path)));
  //     }
  //     final encryptedFileDetails = await _encrytionService.encryptFile(zippedFile);
  //     zipfileName = basename(zippedFile.path);
  //     processing = false;
  //     path = await _githubService.uploadFileAnonymous(encryptedFileDetails['file'], encryptedFileDetails['password']);
  //     uploading = false;
  //   } else {
  //     path = null;
  //   }
  //   fileLink = path;
  // }

  // Future<String> getFileFromToken(String token) async {
  //   downloading = true;
  //   processing = true;
  //   final password = token.substring(token.length - 16);
  //   final fileCode = token.replaceAll(password, "");
  //   final fileLink = _shortenerService.getShortUrlFromFileCode(fileCode);
  //   processing = false;
  //   final file = await _downloadService.downloadFile(fileLink);
  //   processing = true;
  //   final decryptedFile = await _encrytionService.decryptFile(file, password);
  //   logger.d("decryptedFile path : ${decryptedFile.path}");
  //   if (decryptedFile.path.endsWith('.zip')) {
  //     final unzippedFilePath = await _zipService.unzipFile(decryptedFile);
  //     logger.d("unzippedFile path : $unzippedFilePath");
  //     processing = false;
  //     downloading = false;
  //     return unzippedFilePath;
  //   } else {
  //     processing = false;
  //     downloading = false;
  //     return decryptedFile.parent.path;
  //   }
  // }
}
