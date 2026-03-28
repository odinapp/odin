import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odin_core/odin_core.dart' as core;

class EnvironmentService {
  late final core.OdinEnvironment environment;

  static const _defaults = <String, String>{
    'API_URL': 'https://getodin.com/',
    'API_VERSION': 'v1',
    'SUCCESSFUL_STATUS_CODE': '200',
  };

  Future<core.OdinEnvironment> init() async {
    await dotenv.load(fileName: '.env', isOptional: true);

    final resolved = Map<String, String>.from(dotenv.env);
    for (final e in _defaults.entries) {
      final v = resolved[e.key];
      if (v == null || v.isEmpty) {
        resolved[e.key] = e.value;
      }
    }

    environment = core.OdinEnvironment(
      apiUrl: resolved['API_URL']!,
      apiVersion: resolved['API_VERSION']!,
      successfulStatusCode:
          int.tryParse(resolved['SUCCESSFUL_STATUS_CODE'] ?? '') ?? 200,
    );
    return environment;
  }
}
