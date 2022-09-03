import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odin/model/environment_model.dart';

class EnvironmentService {
  static final env = dotenv;
  late final Environment environment;

  Future<Environment> init() async {
    await dotenv.load(fileName: ".env");

    environment = Environment.fromJson(dotenv.env);

    return environment;
  }
}
