import 'dart:io';

import 'package:dio/dio.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/services/zip_service.dart';

class ShortenerService {
  String token = "";
  final _zipService = locator<ZipService>();
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.shrtco.de/v2/',
  ));

  Future<Response?> get({
    required uri,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response = await _dio.get(uri, queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      if (response.statusCode != 201) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Get Request Failed.", e, st);
      return null;
    }
  }

  Future<Response?> post({
    required uri,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Map<String, dynamic> query = {};
      query.addAll(body ?? {});
      final Response response = await _dio.post(uri, queryParameters: query, options: Options(headers: headers));
      stopwatch.stop();
      logger.d("Last request took : ${stopwatch.elapsedMilliseconds} ms.");
      if (response.statusCode != 201) {
        throw HttpException(response.statusCode.toString());
      }
      return response;
    } catch (e, st) {
      logger.e("Post Request Failed.", e, st);
      return null;
    }
  }

  Future<String?> getFileCode(String url, String password) async {
    logger.d('Fetching short link');
    final Response? response = await post(uri: 'shorten?url=$url');
    if (response != null) {
      final shortLink = response.data["result"]["full_short_link"];
      token = shortLink.replaceAll("https://shrtco.de/", "") + password;
      return token;
    } else {
      return null;
    }
  }

  String getShortUrlFromFileCode(String fileCode) {
    return "https://shrtco.de/$fileCode";
  }

  Future<String> getDynamicLink(String fileCode) async {
    // logger.d('Started building dynamic link');
    // final initialLink = Uri.parse('https://getodin.com/files/$fileCode');
    // final dynamicLinks = FirebaseDynamicLinks.instance;
    // final DynamicLinkParameters parameters = DynamicLinkParameters(
    //   uriPrefix: 'https://getodin.page.link',
    //   link: initialLink,
    //   androidParameters: const AndroidParameters(
    //     packageName: 'com.odin.odin',
    //     minimumVersion: 1,
    //   ),
    //   iosParameters: const IOSParameters(
    //     bundleId: 'com.odin.odin',
    //     minimumVersion: '0.2.0',
    //     appStoreId: '123456789', // Update this value with your app's App Store ID
    //   ),
    //   socialMetaTagParameters: SocialMetaTagParameters(
    //     title: _zipService.linkTitle,
    //     description: _zipService.linkDesc,
    //   ),
    // );
    // final ShortDynamicLink shortenedLink =
    //     await dynamicLinks.buildShortLink(parameters, shortLinkType: ShortDynamicLinkType.short);
    // logger.d('Finished building dynamic link');
    // return shortenedLink.shortUrl.toString();
    return 'deep link not configured';
  }
}
