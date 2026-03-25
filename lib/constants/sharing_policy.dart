/// Upload lifetime and size limits enforced by the Odin API (`odin-worker`).
abstract final class SharingPolicy {
  SharingPolicy._();

  static const int fileLifetimeHours = 24;
  static const int maxUploadBytes = 100 * 1024 * 1024;

  static const String maxUploadShortLabel = '100 MB';
}
