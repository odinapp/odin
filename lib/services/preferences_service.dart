import 'dart:convert';

import 'package:odin/model/pending_upload.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _pendingUploadsKey = 'pending_uploads_v1';

  SharedPreferences? _preferences;

  bool get isReady => _preferences != null;

  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<PendingUpload>> loadPendingUploads() async {
    await init();
    final raw = _preferences!.getString(_pendingUploadsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PendingUpload.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> savePendingUploads(List<PendingUpload> list) async {
    await init();
    await _preferences!.setString(
      _pendingUploadsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  bool getUniversalShare() {
    if (_preferences == null) {
      throw StateError('PreferencesService.init() must be called first');
    }
    bool? universalShare = _preferences!.getBool('universalShare');
    if (universalShare == null) {
      universalShare = false;
      _preferences!.setBool('universalShare', universalShare);
    }
    return universalShare;
  }

  void setUniversalShare(bool value) {
    if (_preferences == null) {
      throw StateError('PreferencesService.init() must be called first');
    }
    _preferences!.setBool('universalShare', value);
  }
}
