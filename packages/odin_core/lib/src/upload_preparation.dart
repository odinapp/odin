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
    required this.downloadFileName,
    required this.originalFiles,
    required this.originalTotalFileSize,
    required this.tempArtifacts,
  });

  final List<File> filesToUpload;
  final int totalFileSize;
  final int inputCount;
  final bool usedCombinedZip;
  final String downloadFileName;
  final List<PreparedFileEntry> originalFiles;
  final int originalTotalFileSize;
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

final class PreparedFileEntry {
  PreparedFileEntry({required this.path, required this.size});

  final String path;
  final int size;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'size': size,
  };
}

Future<PreparedUpload> prepareUploadInputs({
  required List<String> inputPaths,
  Directory? tempDirectory,
  bool zipIfMultiple = false,
}) async {
  if (inputPaths.isEmpty) {
    throw ArgumentError.value(inputPaths, 'inputPaths', 'Must not be empty.');
  }

  final normalized = inputPaths.map(p.normalize).toList(growable: false);
  var hasDirectory = false;
  final files = <File>[];
  final directories = <Directory>[];
  final originalFiles = <PreparedFileEntry>[];
  var originalTotal = 0;

  for (final path in normalized) {
    final type = await FileSystemEntity.type(path, followLinks: true);
    switch (type) {
      case FileSystemEntityType.file:
        final file = File(path);
        files.add(file);
        final size = await file.length();
        originalTotal += size;
        originalFiles.add(
          PreparedFileEntry(path: p.basename(file.path), size: size),
        );
      case FileSystemEntityType.directory:
        hasDirectory = true;
        final dir = Directory(path);
        directories.add(dir);
        await for (final entity in dir.list(
          recursive: true,
          followLinks: true,
        )) {
          if (entity is! File) continue;
          final relative = p.relative(entity.path, from: dir.path);
          final entryPath = p.join(p.basename(dir.path), relative);
          final size = await entity.length();
          originalTotal += size;
          originalFiles.add(PreparedFileEntry(path: entryPath, size: size));
        }
      case FileSystemEntityType.notFound:
        throw FileSystemException('Input path not found', path);
      case FileSystemEntityType.link:
      case FileSystemEntityType.unixDomainSock:
      case FileSystemEntityType.pipe:
        throw FileSystemException('Unsupported input path type', path);
    }
  }

  if (!hasDirectory && !(zipIfMultiple && normalized.length > 1)) {
    var total = 0;
    for (final file in files) {
      total += await file.length();
    }
    return PreparedUpload(
      filesToUpload: files,
      totalFileSize: total,
      inputCount: normalized.length,
      usedCombinedZip: false,
      downloadFileName: p.basename(files.first.path),
      originalFiles: originalFiles,
      originalTotalFileSize: originalTotal,
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
  final downloadFileName = _deriveArchiveName(
    files: files,
    directories: directories,
  );
  return PreparedUpload(
    filesToUpload: <File>[zipFile],
    totalFileSize: size,
    inputCount: normalized.length,
    usedCombinedZip: true,
    downloadFileName: downloadFileName,
    originalFiles: originalFiles,
    originalTotalFileSize: originalTotal,
    tempArtifacts: <File>[zipFile],
  );
}

String _deriveArchiveName({
  required List<File> files,
  required List<Directory> directories,
}) {
  if (files.isEmpty && directories.length == 1) {
    return '${p.basename(directories.first.path)}.zip';
  }
  return 'files.zip';
}
