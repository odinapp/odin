import 'dart:io';

import 'package:archive/archive.dart';
import 'package:odin_core/odin_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('prepareUploadInputs', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('odin_prepare_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('returns raw files for file-only input', () async {
      final fileA = File(p.join(tempDir.path, 'a.txt'))..writeAsStringSync('a');
      final fileB = File(p.join(tempDir.path, 'b.txt'))
        ..writeAsStringSync('bb');

      final prepared = await prepareUploadInputs(
        inputPaths: <String>[fileA.path, fileB.path],
      );

      expect(prepared.usedCombinedZip, isFalse);
      expect(prepared.filesToUpload.map((f) => f.path), [
        fileA.path,
        fileB.path,
      ]);
      expect(prepared.totalFileSize, fileA.lengthSync() + fileB.lengthSync());
      expect(prepared.tempArtifacts, isEmpty);
      expect(prepared.downloadFileName, 'a.txt');
      expect(prepared.originalFiles.length, 2);
    });

    test(
      'creates combined zip for directory input preserving root folder',
      () async {
        final root = Directory(p.join(tempDir.path, 'folder'))..createSync();
        final nested = Directory(p.join(root.path, 'nested'))..createSync();
        final file = File(p.join(nested.path, 'file.txt'))
          ..writeAsStringSync('hello');

        final prepared = await prepareUploadInputs(
          inputPaths: <String>[root.path],
        );

        expect(prepared.usedCombinedZip, isTrue);
        expect(prepared.filesToUpload.length, 1);

        final archiveBytes = prepared.filesToUpload.first.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(archiveBytes);
        final names = archive.files.map((f) => f.name).toList(growable: false);
        expect(names, contains('folder/nested/file.txt'));
        expect(
          prepared.totalFileSize,
          prepared.filesToUpload.first.lengthSync(),
        );
        expect(prepared.downloadFileName, 'folder.zip');
        expect(prepared.originalFiles.first.path, 'folder/nested/file.txt');

        await prepared.cleanupTempArtifacts();
        expect(prepared.filesToUpload.first.existsSync(), isFalse);
        expect(file.existsSync(), isTrue);
      },
    );

    test('creates one combined zip for mixed file and directory', () async {
      final file = File(p.join(tempDir.path, 'top.txt'))
        ..writeAsStringSync('t');
      final root = Directory(p.join(tempDir.path, 'dir'))..createSync();
      File(p.join(root.path, 'inside.txt')).writeAsStringSync('i');

      final prepared = await prepareUploadInputs(
        inputPaths: <String>[file.path, root.path],
      );

      expect(prepared.usedCombinedZip, isTrue);
      expect(prepared.filesToUpload.length, 1);

      final archive = ZipDecoder().decodeBytes(
        prepared.filesToUpload.first.readAsBytesSync(),
      );
      final names = archive.files.map((f) => f.name).toList(growable: false);
      expect(names, contains('top.txt'));
      expect(names, contains('dir/inside.txt'));
    });
  });
}
