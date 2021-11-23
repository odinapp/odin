import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/zip_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  setUpAll(() => setupLocator());
  group("Zip -", () {
    test("Result should be a File", () async {
      final ZipService _zipService = ZipService();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}\\hello.txt');
      file.writeAsStringSync('Hello World!');
      final File zippedFile = await _zipService.zipFile(fileToZips: [file]);
      expect(zippedFile, isA<File>());
    });
    test("Result should be of zip extension", () async {
      final ZipService _zipService = ZipService();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}\\hello2.txt');
      file.writeAsStringSync('Hello World!');
      final File zippedFile = await _zipService.zipFile(fileToZips: [file]);
      expect(basename(zippedFile.path), stringContainsInOrder([".zip"]));
    });
    test("Result should contain first file name", () async {
      final ZipService _zipService = ZipService();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}\\hello3.txt');
      file.writeAsStringSync('Hello World!');
      final file2 = File('${directory.path}\\hello4.txt');
      file2.writeAsStringSync('Hello World!');
      final File zippedFile =
          await _zipService.zipFile(fileToZips: [file, file2]);
      expect(basename(zippedFile.path),
          stringContainsInOrder(["hello3", "txt", ".zip"]));
    });
  });
}
