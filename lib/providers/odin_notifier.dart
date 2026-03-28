import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:odin/amenities/app_info/amenity.dart';
import 'package:odin/constants/sharing_policy.dart';
import 'package:odin/model/config.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/utilities/networking.dart';
import 'package:odin_core/odin_core.dart' as core;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class OdinNotifier with ChangeNotifier {
  double _progress = 0;
  int _progressPercentage = 0;

  List<File> selectedFiles = [];
  int selectedFilesSize = 0;

  final CancelToken _cancelToken = CancelToken();

  double get progress => _progress;
  int get progressPercentage => _progressPercentage;
  CancelToken get cancelToken => _cancelToken;

  // Upload
  core.UploadFilesSuccess? uploadFilesSuccess;
  core.UploadFilesFailure? uploadFilesFailure;

  // Metadata
  core.FetchFilesMetadataSuccess? fetchFilesMetadataSuccess;
  core.FetchFilesMetadataFailure? fetchFilesMetadataFailure;

  // Config
  Config? fetchedConfig;
  core.FetchConfigFailure? fetchConfigFailure;

  // Download
  core.DownloadFileSuccess? downloadFileSuccess;
  core.DownloadFileFailure? downloadFileFailure;

  // Pending uploads
  List<core.PendingUpload> _pendingItems = [];
  List<core.PendingUpload> get pendingItems => List.unmodifiable(_pendingItems);

  // Status streams
  final _apiStatusSubject = BehaviorSubject<ApiStatus>.seeded(ApiStatus.init);
  final _miniApiStatusSubject = BehaviorSubject<ApiStatus>.seeded(
    ApiStatus.init,
  );

  Stream<ApiStatus> get apiStatusStream => _apiStatusSubject.stream;
  ApiStatus? get apiStatus => _apiStatusSubject.valueOrNull;

  Stream<ApiStatus> get miniApiStatusStream => _miniApiStatusSubject.stream;
  ApiStatus? get miniApiStatus => _miniApiStatusSubject.valueOrNull;

  set apiStatus(ApiStatus? value) {
    _apiStatusSubject.add(value ?? ApiStatus.init);
    notifyListeners();
  }

  set miniApiStatus(ApiStatus? value) {
    _miniApiStatusSubject.add(value ?? ApiStatus.init);
    notifyListeners();
  }

  Future<core.OdinRepository> _createRepository() async {
    final timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    final config = core.OdinClientConfig(
      environment: locator<EnvironmentService>().environment,
      appVersion: AppInfoAmenity.instance.info.version,
      timezone: timezone,
    );
    return core.OdinRepositoryImpl(config: config);
  }

  Future<String> getSaveDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    // Desktop: prefer Downloads, fall back to Documents
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads.path;
    } catch (_) {}
    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  Future<File> createDummyFile() async {
    const exampleString = 'Example file contents';
    final tempDir = await getTemporaryDirectory();
    final exampleFile = File('${tempDir.path}/example.txt')
      ..createSync()
      ..writeAsStringSync(exampleString);
    return exampleFile;
  }

  // --- Network calls ---

  Future<void> uploadFilesAnonymous(
    List<File> files,
    void Function(int, int)? onSendProgress,
  ) async {
    selectedFiles = files;
    _progress = 0;
    _progressPercentage = 0;
    apiStatus = ApiStatus.loading;
    notifyListeners();

    final repo = await _createRepository();
    selectedFilesSize = 0;
    for (final file in files) {
      selectedFilesSize += await file.length();
    }
    notifyListeners();

    final result = await repo.uploadFilesAnonymous(
      request: core.UploadFilesRequest(
        files: files,
        onSendProgress: (count, total) {
          if (total > 0) {
            _progress = count / total;
            _progressPercentage = (_progress * 100).toInt();
          }
          onSendProgress?.call(count, total);
          notifyListeners();
        },
        cancelToken: _cancelToken,
      ),
    );

    result.resolve(
      (success) {
        apiStatus = ApiStatus.success;
        uploadFilesSuccess = success;
        uploadFilesFailure = null;
        notifyListeners();
        logger.d('[OdinNotifier]: UploadFilesSuccess ${success.message}');
        final delete = success.deleteToken;
        if (delete != null && delete.isNotEmpty) {
          unawaited(_persistPendingUpload(success, delete));
        }
      },
      (failure) {
        apiStatus = ApiStatus.failed;
        uploadFilesSuccess = null;
        uploadFilesFailure = failure;
        notifyListeners();
        logger.d('[OdinNotifier]: UploadFilesFailure ${failure.message}');
      },
    );
  }

  Future<void> fetchFilesMetadata(
    String token,
    void Function(int, int)? onReceiveProgress,
  ) async {
    miniApiStatus = ApiStatus.loading;
    notifyListeners();

    final repo = await _createRepository();
    final result = await repo.fetchFilesMetadata(
      request: core.FetchFilesMetadataRequest(
        token: token,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            _progress = count / total;
            _progressPercentage = (_progress * 100).toInt();
            notifyListeners();
          }
          onReceiveProgress?.call(count, total);
        },
        cancelToken: _cancelToken,
      ),
    );

    result.resolve(
      (success) {
        miniApiStatus = ApiStatus.success;
        fetchFilesMetadataSuccess = success;
        fetchFilesMetadataFailure = null;
        notifyListeners();
        logger.d(
          '[OdinNotifier]: FetchFilesMetadataSuccess ${success.message}',
        );
      },
      (failure) {
        miniApiStatus = ApiStatus.failed;
        fetchFilesMetadataSuccess = null;
        fetchFilesMetadataFailure = failure;
        notifyListeners();
        logger.d(
          '[OdinNotifier]: FetchFilesMetadataFailure ${failure.message}',
        );
      },
    );
  }

  Future<void> fetchConfig(void Function(int, int)? onReceiveProgress) async {
    final repo = await _createRepository();
    final result = await repo.fetchConfig(
      request: core.FetchConfigRequest(
        onReceiveProgress: onReceiveProgress,
        cancelToken: _cancelToken,
      ),
    );

    result.resolve(
      (success) {
        fetchedConfig = Config.fromJson(success.config);
        fetchConfigFailure = null;
        notifyListeners();
        logger.d('[OdinNotifier]: FetchConfigSuccess');
      },
      (failure) {
        fetchedConfig = null;
        fetchConfigFailure = failure;
        notifyListeners();
        logger.d('[OdinNotifier]: FetchConfigFailure ${failure.message}');
      },
    );
  }

  Future<void> downloadFile(
    String token,
    String savePath,
    void Function(int, int)? onReceiveProgress,
  ) async {
    _progress = 0;
    _progressPercentage = 0;
    apiStatus = ApiStatus.loading;
    notifyListeners();

    final repo = await _createRepository();
    final result = await repo.downloadFile(
      request: core.DownloadFileRequest(
        token: token,
        savePath: savePath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            _progress = count / total;
            _progressPercentage = (_progress * 100).toInt();
            notifyListeners();
          }
          onReceiveProgress?.call(count, total);
        },
        cancelToken: _cancelToken,
      ),
    );

    result.resolve(
      (success) {
        downloadFileSuccess = success;
        downloadFileFailure = null;
        apiStatus = ApiStatus.init;
        notifyListeners();
        logger.d('[OdinNotifier]: DownloadFileSuccess ${success.message}');
      },
      (failure) {
        downloadFileSuccess = null;
        downloadFileFailure = failure;
        apiStatus = ApiStatus.init;
        notifyListeners();
        logger.d('[OdinNotifier]: DownloadFileFailure ${failure.message}');
      },
    );
  }

  Future<void> cancelCurrentRequest() async {
    apiStatus = ApiStatus.failed;
    _cancelToken.cancel();
    notifyListeners();
  }

  Future<void> cancelMiniRequest() async {
    miniApiStatus = ApiStatus.failed;
    _cancelToken.cancel();
    notifyListeners();
  }

  // --- Pending uploads ---

  Future<void> refreshPendingUploads() async {
    final storage = locator<core.OdinStorage>();
    await storage.init();
    final list = await storage.loadPendingUploads();
    final now = DateTime.now();
    final fresh = list.where((u) => u.expiresAt.isAfter(now)).toList();
    if (fresh.length != list.length) {
      await storage.savePendingUploads(fresh);
    }
    _pendingItems = fresh;
    notifyListeners();
  }

  Future<void> recordPendingUpload({
    required String shareToken,
    required String deleteUrl,
    String? fileSummary,
  }) async {
    final storage = locator<core.OdinStorage>();
    await storage.init();
    var list = await storage.loadPendingUploads();
    list = list.where((u) => u.deleteUrl != deleteUrl).toList();
    final now = DateTime.now();
    list.insert(
      0,
      core.PendingUpload(
        id: now.millisecondsSinceEpoch.toString(),
        shareToken: shareToken,
        deleteUrl: deleteUrl,
        expiresAt: now.add(Duration(hours: SharingPolicy.fileLifetimeHours)),
        createdAt: now,
        fileSummary: fileSummary,
      ),
    );
    await storage.savePendingUploads(list);
    _pendingItems = list
        .where((u) => u.expiresAt.isAfter(DateTime.now()))
        .toList();
    notifyListeners();
  }

  Future<bool> deleteUploadOnServer(core.PendingUpload upload) async {
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
        final storage = locator<core.OdinStorage>();
        await storage.init();
        final list = (await storage.loadPendingUploads())
            .where((u) => u.id != upload.id)
            .toList();
        await storage.savePendingUploads(list);
        _pendingItems = list
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

  static String timeRemainingLabel(core.PendingUpload u) {
    final d = u.expiresAt.difference(DateTime.now());
    if (d.isNegative) return 'Expired';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m left';
    if (m > 0) return '${m}m left';
    return 'Soon';
  }

  Future<void> _persistPendingUpload(
    core.UploadFilesSuccess success,
    String deleteUrl,
  ) async {
    try {
      await recordPendingUpload(
        shareToken: success.token,
        deleteUrl: deleteUrl,
        fileSummary: _selectedFilesSummaryLabel(),
      );
    } catch (e, st) {
      logger.e('recordPendingUpload', error: e, stackTrace: st);
    }
  }

  String? _selectedFilesSummaryLabel() {
    if (selectedFiles.isEmpty) return null;
    if (selectedFiles.length == 1) {
      return selectedFiles.first.path.split(RegExp(r'[/\\]')).last;
    }
    return '${selectedFiles.length} files';
  }
}
