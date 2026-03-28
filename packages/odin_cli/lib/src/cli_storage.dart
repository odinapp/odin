import 'dart:convert';
import 'dart:io';

import 'package:odin_core/odin_core.dart';
import 'package:path/path.dart' as p;

/// Same TTL as [SharingPolicy.fileLifetimeHours] in the Flutter app (`lib/constants/sharing_policy.dart`).
const int kPendingUploadTtlHours = 24;

/// JSON file under `~/.odin/pending_uploads.json` (or `%USERPROFILE%\.odin\` on Windows).
final class CliOdinStorage implements OdinStorage {
  CliOdinStorage();

  File? _file;
  bool _inited = false;

  File _pendingFile() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final dir = Directory(p.join(home, '.odin'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File(p.join(dir.path, 'pending_uploads.json'));
  }

  @override
  Future<void> init() async {
    if (_inited) return;
    _file = _pendingFile();
    _inited = true;
  }

  @override
  Future<List<PendingUpload>> loadPendingUploads() async {
    await init();
    final f = _file!;
    if (!f.existsSync()) return [];
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (e) => PendingUpload.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  @override
  Future<void> savePendingUploads(List<PendingUpload> list) async {
    await init();
    await _file!.writeAsString(
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  @override
  bool getUniversalShare() => false;

  @override
  void setUniversalShare(bool value) {}
}
