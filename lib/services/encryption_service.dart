import 'dart:io';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:path/path.dart';

class EncryptionService {
  final RandomService _randomService = locator<RandomService>();

  Future<File> encryptFile(File file) async {
    logger.d('Started Encryption');
    final crypt = AesCrypt();
    final password = _randomService.getRandomString(16);
    crypt.setPassword(password);
    logger.i('Password: $password');
    crypt.encryptFileSync(
        file.path, basenameWithoutExtension(file.path) + '.odin');
    logger.d('Finished Encryption');
    return File(basenameWithoutExtension(file.path) + '.odin');
  }
}
