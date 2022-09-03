import 'package:json_annotation/json_annotation.dart';

part 'environment_model.g.dart';

/// Model class for the environment variables
@JsonSerializable()
class Environment {
  Environment(this.API_URL, this.API_VERSION);

  final String API_URL;
  final String API_VERSION;

  factory Environment.fromJson(Map<String, dynamic> input) => _$EnvironmentFromJson(input);

  Map<String, dynamic> toJson() => _$EnvironmentToJson(this);
}
