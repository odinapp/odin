import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;

import 'result.dart';

/// Missing variables after merging optional `.env`, process environment, and
/// CLI overrides (`resolveForCli`).
class OdinEnvironmentConfigError {
  OdinEnvironmentConfigError({required this.missingVariables});

  final List<String> missingVariables;

  String get message {
    final names = missingVariables.join(', ');
    final buf = StringBuffer()
      ..writeln('Missing required Odin configuration: $names.')
      ..writeln()
      ..writeln('Set them in your shell before running the CLI, for example:')
      ..writeln('  export API_URL=https://example.com/')
      ..writeln('  export API_VERSION=v1')
      ..writeln()
      ..writeln(
        'You can also pass --api-url and/or --api-version, and optionally '
        '--env-file /path/to/.env. Process environment variables override '
        'values from the file.',
      );
    return buf.toString().trimRight();
  }
}

class OdinEnvironment {
  OdinEnvironment({
    required this.apiUrl,
    required this.apiVersion,
    required this.successfulStatusCode,
  });

  final String apiUrl;
  final String apiVersion;
  final int successfulStatusCode;

  static const _configKeys = <String>[
    'API_URL',
    'API_VERSION',
    'SUCCESSFUL_STATUS_CODE',
  ];

  /// Resolves API base configuration for the CLI.
  ///
  /// Merge order (later wins): optional [envFilePath] (if the file exists),
  /// [Platform.environment], then [apiUrlOverride] / [apiVersionOverride].
  ///
  /// [API_URL] and [API_VERSION] must end up non-empty after merging.
  /// [SUCCESSFUL_STATUS_CODE] is optional and defaults to `200`.
  ///
  /// When [environmentForTesting] is non-null, it replaces [Platform.environment]
  /// for the process-env merge step (intended for tests).
  static Result<OdinEnvironment, OdinEnvironmentConfigError> resolveForCli({
    String? envFilePath,
    String? apiUrlOverride,
    String? apiVersionOverride,
    Map<String, String>? environmentForTesting,
  }) {
    final processEnv = environmentForTesting ?? Platform.environment;
    final merged = <String, String>{};

    if (envFilePath != null) {
      final file = File(envFilePath);
      if (file.existsSync()) {
        final fileEnv = dotenv.DotEnv(
          includePlatformEnvironment: false,
          quiet: true,
        )..load(<String>[envFilePath]);
        for (final key in _configKeys) {
          final v = fileEnv[key];
          final t = v?.trim();
          if (t != null && t.isNotEmpty) {
            merged[key] = t;
          }
        }
      }
    }

    for (final key in _configKeys) {
      final v = processEnv[key];
      final t = v?.trim();
      if (t != null && t.isNotEmpty) {
        merged[key] = t;
      }
    }

    final url = _nonEmpty(apiUrlOverride) ?? merged['API_URL'];
    final version = _nonEmpty(apiVersionOverride) ?? merged['API_VERSION'];
    final successRaw = merged['SUCCESSFUL_STATUS_CODE'];
    final successCode = int.tryParse(successRaw ?? '') ?? 200;

    final missing = <String>[];
    if (url == null || url.isEmpty) {
      missing.add('API_URL');
    }
    if (version == null || version.isEmpty) {
      missing.add('API_VERSION');
    }
    if (missing.isNotEmpty) {
      return Failure(OdinEnvironmentConfigError(missingVariables: missing));
    }

    // Non-null after [missing] checks above.
    return Success(
      OdinEnvironment(
        apiUrl: url!,
        apiVersion: version!,
        successfulStatusCode: successCode,
      ),
    );
  }

  static String? _nonEmpty(String? s) {
    if (s == null) {
      return null;
    }
    final t = s.trim();
    return t.isEmpty ? null : t;
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
