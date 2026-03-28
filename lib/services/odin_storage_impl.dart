import 'dart:convert';

import 'package:odin_core/odin_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';

/// Flutter implementation of [core.OdinStorage] backed by [SharedPreferences].
class OdinStorageImpl implements core.OdinStorage {
  static const _pendingUploadsKey = 'pending_uploads_v1';

  SharedPreferences? _preferences;

  @override
  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<core.PendingUpload>> loadPendingUploads() async {
    await init();
    final raw = _preferences!.getString(_pendingUploadsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (e) =>
              core.PendingUpload.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<void> savePendingUploads(List<core.PendingUpload> list) async {
    await init();
    await _preferences!.setString(
      _pendingUploadsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  @override
  bool getUniversalShare() {
    if (_preferences == null) {
      throw StateError('OdinStorageImpl.init() must be called first');
    }
    return _preferences!.getBool('universalShare') ?? false;
  }

  @override
  void setUniversalShare(bool value) {
    if (_preferences == null) {
      throw StateError('OdinStorageImpl.init() must be called first');
    }
    _preferences!.setBool('universalShare', value);
  }
}
