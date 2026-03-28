import 'models/pending_upload.dart';

/// Abstract storage interface for persisting Odin app state.
///
/// Implement in the host app (Flutter via shared_preferences, CLI via JSON
/// file, etc.) and register the concrete instance in the service locator.
abstract class OdinStorage {
  /// Initialise the backing store. Must be called before any read/write.
  /// Implementations should be idempotent — safe to call multiple times.
  Future<void> init();

  Future<List<PendingUpload>> loadPendingUploads();

  Future<void> savePendingUploads(List<PendingUpload> list);

  /// Returns the persisted universal-share preference (default: false).
  bool getUniversalShare();

  void setUniversalShare(bool value);
}
