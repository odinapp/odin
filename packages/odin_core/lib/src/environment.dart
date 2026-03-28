import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;

class OdinEnvironment {
  OdinEnvironment({
    required this.apiUrl,
    required this.apiVersion,
    required this.successfulStatusCode,
  });

  final String apiUrl;
  final String apiVersion;
  final int successfulStatusCode;

  static const _defaults = <String, String>{
    'API_URL': 'https://getodin.com/',
    'API_VERSION': 'v1',
    'SUCCESSFUL_STATUS_CODE': '200',
  };

  static OdinEnvironment load({String envFilePath = '.env'}) {
    final env = dotenv.DotEnv(includePlatformEnvironment: true, quiet: true)
      ..load(<String>[envFilePath]);

    final resolved = <String, String>{
      ..._defaults,
      for (final key in _defaults.keys)
        if (env[key] != null) key: env[key]!,
    };
    final successCode =
        int.tryParse(
          resolved['SUCCESSFUL_STATUS_CODE'] ??
              _defaults['SUCCESSFUL_STATUS_CODE']!,
        ) ??
        200;

    return OdinEnvironment(
      apiUrl: resolved['API_URL']!,
      apiVersion: resolved['API_VERSION']!,
      successfulStatusCode: successCode,
    );
  }
}

class OdinClientConfig {
  OdinClientConfig({
    required this.environment,
    String? appVersion,
    String? timezone,
    Duration? connectTimeout,
  }) : appVersion = appVersion ?? 'odin-cli-dev',
       timezone = timezone ?? Platform.environment['TZ'] ?? 'UTC',
       connectTimeout = connectTimeout ?? const Duration(milliseconds: 3000);

  final OdinEnvironment environment;
  final String appVersion;
  final String timezone;
  final Duration connectTimeout;

  String get baseUrl {
    final normalizedApiUrl = environment.apiUrl.endsWith('/')
        ? environment.apiUrl
        : '${environment.apiUrl}/';
    final normalizedApiVersion = environment.apiVersion
        .replaceAll(RegExp('^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');
    return '${normalizedApiUrl}api/$normalizedApiVersion/';
  }
}
