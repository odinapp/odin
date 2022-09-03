import 'dart:io';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:cross_file/cross_file.dart';
import 'package:odin/model/encrypted_file.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:path/path.dart';

class EncryptionService {
  final RandomService _randomService = locator<RandomService>();

  Future<EncryptedFile> encryptFile(File file) async {
    logger.d('Started Encryption');
    final crypt = AesCrypt();
    final password = _randomService.getRandomString(16);
    crypt.setPassword(password);
    crypt.setOverwriteMode(AesCryptOwMode.rename);
    final encryptedFilePath = join(file.parent.path, '${basename(file.path)}.odin');
    crypt.encryptFileSync(file.path, encryptedFilePath);
    file.deleteSync(); // Delete the original zip file
    logger.d('Finished Encryption');

    final encryptedFile = EncryptedFile(XFile(encryptedFilePath), password);

    return encryptedFile;
  }

  Future<File> decryptFile(EncryptedFile encryptedFile) async {
    logger.d('Started Deryption');
    var file = File(encryptedFile.file.path);
    final password = encryptedFile.password;
    final crypt = AesCrypt();
    crypt.setPassword(password);
    crypt.setOverwriteMode(AesCryptOwMode.rename);
    file = await file.rename("${file.path.substring(0, file.path.length - 5)}.aes");
    final decryptedFilePath =
        crypt.decryptFileSync(file.path, join(file.parent.path, basenameWithoutExtension(file.path)));
    File decryptedFile = File(decryptedFilePath);
    file.deleteSync(); // Delete the original AES file
    logger.d('Finished Decryption');
    return decryptedFile;
  }
}
