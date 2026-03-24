import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odin/model/environment_model.dart';

class EnvironmentService {
  static final env = dotenv;
  late final Environment environment;

  /// Defaults when `.env` omits keys (avoids null cast in [Environment.fromJson]).
  static const _defaults = <String, String>{
    'API_URL': 'https://getodin.com/',
    'API_VERSION': 'v1',
    'SUCCESSFUL_STATUS_CODE': '200',
  };

  Future<Environment> init() async {
    await dotenv.load(fileName: '.env', isOptional: true);

    final resolved = Map<String, String>.from(dotenv.env);
    for (final e in _defaults.entries) {
      final v = resolved[e.key];
      if (v == null || v.isEmpty) {
        resolved[e.key] = e.value;
      }
    }

    environment = Environment.fromJson(resolved);
    return environment;
  }
}
