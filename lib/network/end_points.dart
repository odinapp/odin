part of './repository_impl.dart';

class _EndPoint {
  _EndPoint._();
  // static String channelDetails(channelId) => 'api/v3/channels/$channelId/';
  // static String channels(familyId) => 'api/v3/communities/$familyId/channels/';
  static const String uploadFiles = 'file/upload/';
  static const String fetchFilesMetadata = 'file/info/';
}
