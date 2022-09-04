part of 'networking_box.dart';

class ONetworkingOptions {
  final String? baseUrl;
  final ResponseType? responseType;
  final Map<String, String>? headers;

  ONetworkingOptions({
    this.baseUrl,
    this.headers,
    this.responseType,
  });
}
