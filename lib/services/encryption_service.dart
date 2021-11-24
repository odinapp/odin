import 'dart:io';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/random_service.dart';
import 'package:path/path.dart';

class EncryptionService {
  final RandomService _randomService = locator<RandomService>();

  Future<File> encryptFile({
    required File file,
  }) async {
    logger.d('Started Encryption');
    final crypt = AesCrypt();
    crypt.setPassword(_randomService.getRandomString(16));
    crypt.encryptFileSync(
        file.path, basenameWithoutExtension(file.path) + '.odin');
    logger.d('Finished Zipping Files');
    return File(basenameWithoutExtension(file.path) + '.odin');
  }
}
