import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:odin/constants/sharing_policy.dart';
import 'package:odin/model/pending_upload.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/preferences_service.dart';

/// Local cache of uploads the user may delete early via [deleteUrl].
class PendingUploadsNotifier extends ChangeNotifier {
  PendingUploadsNotifier();

  final PreferencesService _prefs = locator<PreferencesService>();

  List<PendingUpload> _items = [];

  List<PendingUpload> get items => List.unmodifiable(_items);

  /// Loads from SharedPreferences and drops expired rows.
  Future<void> refresh() async {
    await _prefs.init();
    var list = await _prefs.loadPendingUploads();
    final now = DateTime.now();
    final fresh = list.where((u) => u.expiresAt.isAfter(now)).toList();
    if (fresh.length != list.length) {
      await _prefs.savePendingUploads(fresh);
    }
    _items = fresh;
    notifyListeners();
  }

  Future<void> recordPendingUpload({
    required String shareToken,
    required String deleteUrl,
    String? fileSummary,
  }) async {
    await _prefs.init();
    var list = await _prefs.loadPendingUploads();
    list = list.where((u) => u.deleteUrl != deleteUrl).toList();
    final now = DateTime.now();
    list.insert(
      0,
      PendingUpload(
        id: now.millisecondsSinceEpoch.toString(),
        shareToken: shareToken,
        deleteUrl: deleteUrl,
        expiresAt: now.add(Duration(hours: SharingPolicy.fileLifetimeHours)),
        createdAt: now,
        fileSummary: fileSummary,
      ),
    );
    await _prefs.savePendingUploads(list);
    _items = list.where((u) => u.expiresAt.isAfter(DateTime.now())).toList();
    notifyListeners();
  }

  Future<bool> deleteUploadOnServer(PendingUpload upload) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
          validateStatus: (code) => code != null && code < 500,
          followRedirects: true,
          responseType: ResponseType.plain,
        ),
      );
      final response = await dio.get<dynamic>(upload.deleteUrl);
      final code = response.statusCode ?? 0;
      final ok = code >= 200 && code < 400;
      if (ok) {
        await _prefs.init();
        final list = (await _prefs.loadPendingUploads())
            .where((u) => u.id != upload.id)
            .toList();
        await _prefs.savePendingUploads(list);
        _items = list
            .where((u) => u.expiresAt.isAfter(DateTime.now()))
            .toList();
        notifyListeners();
      }
      return ok;
    } catch (e, st) {
      logger.e('deleteUploadOnServer', error: e, stackTrace: st);
      return false;
    }
  }

  static String timeRemainingLabel(PendingUpload u) {
    final d = u.expiresAt.difference(DateTime.now());
    if (d.isNegative) return 'Expired';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m left';
    if (m > 0) return '${m}m left';
    return 'Soon';
  }
}
