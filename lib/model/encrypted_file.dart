import 'package:cross_file/cross_file.dart';

class EncryptedFile {
  EncryptedFile(
    this.file,
    this.password,
  );

  final XFile file;
  final String password;
}
