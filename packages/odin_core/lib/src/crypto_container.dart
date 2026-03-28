import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

const String odinEncryptedMagic = 'ODINENC2';
const int odinEncryptedVersion = 2;
const int _nonceLength = 12;

final class EncryptedUploadArtifact {
  EncryptedUploadArtifact({
    required this.file,
    required this.key,
    required this.tempArtifacts,
    required this.originalFileName,
    required this.zipped,
    required this.manifestPreviewJson,
  });

  final File file;
  final List<int> key;
  final List<File> tempArtifacts;
  final String originalFileName;
  final bool zipped;
  final String manifestPreviewJson;

  Future<void> cleanup() async {
    for (final artifact in tempArtifacts) {
      if (await artifact.exists()) {
        await artifact.delete();
      }
    }
  }
}

Future<EncryptedUploadArtifact> encryptUploadFile({
  required File sourceFile,
  required bool zipped,
  required String outputFileName,
  required List<Map<String, dynamic>> originalFiles,
  required int originalTotalFileSize,
  required Directory tempDirectory,
}) async {
  final random = Random.secure();
  final masterKey = _randomBytes(random, 32);
  final nonce = _randomBytes(random, _nonceLength);

  final bytes = await sourceFile.readAsBytes();
  final manifest = <String, dynamic>{
    'name': outputFileName,
    'size': originalTotalFileSize,
    'zipped': zipped,
    'mime': 'application/octet-stream',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'files': originalFiles,
    'fileCount': originalFiles.length,
    'containerSize': bytes.length,
  };
  final manifestBytes = utf8.encode(jsonEncode(manifest));

  final plain = BytesBuilder(copy: false)
    ..add(_uint32Bytes(manifestBytes.length))
    ..add(manifestBytes)
    ..add(bytes);

  final algorithm = AesGcm.with256bits();
  final secretBox = await algorithm.encrypt(
    plain.takeBytes(),
    secretKey: SecretKey(masterKey),
    nonce: nonce,
  );

  if (!await tempDirectory.exists()) {
    await tempDirectory.create(recursive: true);
  }
  final output = File(
    p.join(
      tempDirectory.path,
      'odin_enc_${DateTime.now().microsecondsSinceEpoch}_${_hexSuffix(random)}.odin',
    ),
  );

  final container = BytesBuilder(copy: false)
    ..add(utf8.encode(odinEncryptedMagic))
    ..addByte(odinEncryptedVersion)
    ..add(nonce)
    ..add(_uint32Bytes(secretBox.cipherText.length))
    ..add(secretBox.cipherText)
    ..add(secretBox.mac.bytes);

  await output.writeAsBytes(container.takeBytes(), flush: true);

  return EncryptedUploadArtifact(
    file: output,
    key: masterKey,
    tempArtifacts: <File>[output],
    originalFileName: outputFileName,
    zipped: zipped,
    manifestPreviewJson: jsonEncode(manifest),
  );
}

bool isEncryptedContainer(List<int> bytes) {
  if (bytes.length < odinEncryptedMagic.length + 1) {
    return false;
  }
  final prefix = utf8.decode(
    bytes.sublist(0, odinEncryptedMagic.length),
    allowMalformed: true,
  );
  return prefix == odinEncryptedMagic;
}

Uint8List _uint32Bytes(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.big);
  return data.buffer.asUint8List();
}

String _hexSuffix(Random random) {
  final bytes = _randomBytes(random, 4);
  final value =
      (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  return value.toRadixString(16);
}

List<int> _randomBytes(Random random, int length) {
  return List<int>.generate(
    length,
    (_) => random.nextInt(256),
    growable: false,
  );
}
