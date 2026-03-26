import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

final class PreparedUpload {
  PreparedUpload({
    required this.filesToUpload,
    required this.totalFileSize,
    required this.inputCount,
    required this.usedCombinedZip,
    required this.tempArtifacts,
  });

  final List<File> filesToUpload;
  final int totalFileSize;
  final int inputCount;
  final bool usedCombinedZip;
  final List<File> tempArtifacts;

  String? get archivePath => usedCombinedZip && filesToUpload.isNotEmpty
      ? filesToUpload.first.path
      : null;

  Future<void> cleanupTempArtifacts() async {
    for (final file in tempArtifacts) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

Future<PreparedUpload> prepareUploadInputs({
  required List<String> inputPaths,
  Directory? tempDirectory,
}) async {
  if (inputPaths.isEmpty) {
    throw ArgumentError.value(inputPaths, 'inputPaths', 'Must not be empty.');
  }

  final normalized = inputPaths.map(p.normalize).toList(growable: false);
  var hasDirectory = false;
  final files = <File>[];
  final directories = <Directory>[];

  for (final path in normalized) {
    final type = await FileSystemEntity.type(path, followLinks: true);
    switch (type) {
      case FileSystemEntityType.file:
        files.add(File(path));
      case FileSystemEntityType.directory:
        hasDirectory = true;
        directories.add(Directory(path));
      case FileSystemEntityType.notFound:
        throw FileSystemException('Input path not found', path);
      case FileSystemEntityType.link:
      case FileSystemEntityType.unixDomainSock:
      case FileSystemEntityType.pipe:
        throw FileSystemException('Unsupported input path type', path);
    }
  }

  if (!hasDirectory) {
    var total = 0;
    for (final file in files) {
      total += await file.length();
    }
    return PreparedUpload(
      filesToUpload: files,
      totalFileSize: total,
      inputCount: normalized.length,
      usedCombinedZip: false,
      tempArtifacts: const <File>[],
    );
  }

  final tempRoot = tempDirectory ?? Directory.systemTemp;
  if (!await tempRoot.exists()) {
    await tempRoot.create(recursive: true);
  }

  final randomSuffix = Random.secure().nextInt(1 << 32).toRadixString(16);
  final zipPath = p.join(
    tempRoot.path,
    'odin_upload_${DateTime.now().millisecondsSinceEpoch}_$randomSuffix.zip',
  );
  final zipFile = File(zipPath);

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);
  try {
    for (final dir in directories) {
      await encoder.addDirectory(dir, includeDirName: true);
    }
    for (final file in files) {
      await encoder.addFile(file, p.basename(file.path));
    }
  } finally {
    await encoder.close();
  }

  final size = await zipFile.length();
  return PreparedUpload(
    filesToUpload: <File>[zipFile],
    totalFileSize: size,
    inputCount: normalized.length,
    usedCombinedZip: true,
    tempArtifacts: <File>[zipFile],
  );
}
