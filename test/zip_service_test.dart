import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/services/zip_service.dart';
import 'package:path/path.dart';

void main() {
  setUpAll(() {
    if (!locator.isRegistered<RandomService>()) {
      locator.registerLazySingleton<RandomService>(() => RandomService());
    }
  });

  group("Zip -", () {
    test("Result should be a File", () async {
      final ZipService zipService = ZipService();
      final directory = Directory.systemTemp;
      final file = File(join(directory.path, 'odin_zip_test_hello.txt'));
      file.writeAsStringSync('Hello World!');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      final File zippedFile = await zipService.zipFile(fileToZips: [file]);
      addTearDown(() {
        if (zippedFile.existsSync()) zippedFile.deleteSync();
      });
      expect(zippedFile, isA<File>());
    });
    test("Result should be of zip extension", () async {
      final ZipService zipService = ZipService();
      final directory = Directory.systemTemp;
      final file = File(join(directory.path, 'odin_zip_test_hello2.txt'));
      file.writeAsStringSync('Hello World!');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      final File zippedFile = await zipService.zipFile(fileToZips: [file]);
      addTearDown(() {
        if (zippedFile.existsSync()) zippedFile.deleteSync();
      });
      expect(basename(zippedFile.path), stringContainsInOrder([".zip"]));
    });
    test("Result should contain first file name", () async {
      final ZipService zipService = ZipService();
      final directory = Directory.systemTemp;
      final file = File(join(directory.path, 'odin_zip_test_hello3.txt'));
      file.writeAsStringSync('Hello World!');
      final file2 = File(join(directory.path, 'odin_zip_test_hello4.txt'));
      file2.writeAsStringSync('Hello World!');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
        if (file2.existsSync()) file2.deleteSync();
      });
      final File zippedFile = await zipService.zipFile(
        fileToZips: [file, file2],
      );
      addTearDown(() {
        if (zippedFile.existsSync()) zippedFile.deleteSync();
      });
      expect(
        basename(zippedFile.path),
        stringContainsInOrder(["hello3", "txt", ".zip"]),
      );
    });
  });
}
