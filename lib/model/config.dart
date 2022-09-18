import 'package:json_annotation/json_annotation.dart';

// part 'config.g.dart';

/// Model class for the config
@JsonSerializable()
class Config {
  Config({
    required this.home,
    required this.upload,
    required this.token,
  });

  final HomeConfig home;
  final UploadConfig upload;
  final TokenConfig token;

  factory Config.fromJson(Map<String, dynamic> input) => _$ConfigFromJson(input);

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}

@JsonSerializable()
class HomeConfig {
  HomeConfig({
    required this.title,
    required this.primaryButtonText,
    required this.secondaryButtonText,
  });

  final String title;
  final String primaryButtonText;
  final String secondaryButtonText;

  factory HomeConfig.fromJson(Map<String, dynamic> input) => _$HomeConfigFromJson(input);

  Map<String, dynamic> toJson() => _$HomeConfigToJson(this);
}

@JsonSerializable()
class UploadConfig {
  UploadConfig({
    required this.title,
    required this.description,
    required this.backButtonText,
    required this.cancelDefaultText,
    required this.errorButtonText,
    required this.errorDefaultText,
    required this.successDefaultText,
  });

  final String title;
  final String description;
  final String backButtonText;
  final String cancelDefaultText;
  final String errorButtonText;
  final String errorDefaultText;
  final String successDefaultText;

  factory UploadConfig.fromJson(Map<String, dynamic> input) => _$UploadConfigFromJson(input);

  Map<String, dynamic> toJson() => _$UploadConfigToJson(this);
}

@JsonSerializable()
class TokenConfig {
  TokenConfig({
    required this.title,
    required this.description,
    required this.textFieldHintText,
    required this.backButtonText,
    required this.primaryButtonText,
  });

  final String title;
  final String description;
  final String textFieldHintText;
  final String backButtonText;
  final String primaryButtonText;

  factory TokenConfig.fromJson(Map<String, dynamic> input) => _$TokenConfigFromJson(input);

  Map<String, dynamic> toJson() => _$TokenConfigToJson(this);
}

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
      home: HomeConfig.fromJson(json['home'] as Map<String, dynamic>),
      upload: UploadConfig.fromJson(json['upload'] as Map<String, dynamic>),
      token: TokenConfig.fromJson(json['token'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'home': instance.home,
      'upload': instance.upload,
      'token': instance.token,
    };

HomeConfig _$HomeConfigFromJson(Map<String, dynamic> json) => HomeConfig(
      title: (json['title'] as String).replaceAll('\\n', '\n'),
      primaryButtonText: (json['primaryButtonText'] as String).replaceAll('\\n', '\n'),
      secondaryButtonText: (json['secondaryButtonText'] as String).replaceAll('\\n', '\n'),
    );

Map<String, dynamic> _$HomeConfigToJson(HomeConfig instance) => <String, dynamic>{
      'title': instance.title,
      'primaryButtonText': instance.primaryButtonText,
      'secondaryButtonText': instance.secondaryButtonText,
    };

UploadConfig _$UploadConfigFromJson(Map<String, dynamic> json) => UploadConfig(
      title: (json['title'] as String).replaceAll('\\n', '\n'),
      description: (json['description'] as String).replaceAll('\\n', '\n'),
      backButtonText: (json['backButtonText'] as String).replaceAll('\\n', '\n'),
      cancelDefaultText: (json['cancelDefaultText'] as String).replaceAll('\\n', '\n'),
      errorButtonText: (json['errorButtonText'] as String).replaceAll('\\n', '\n'),
      errorDefaultText: (json['errorDefaultText'] as String).replaceAll('\\n', '\n'),
      successDefaultText: (json['successDefaultText'] as String).replaceAll('\\n', '\n'),
    );

Map<String, dynamic> _$UploadConfigToJson(UploadConfig instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'backButtonText': instance.backButtonText,
      'cancelDefaultText': instance.cancelDefaultText,
      'errorButtonText': instance.errorButtonText,
      'errorDefaultText': instance.errorDefaultText,
      'successDefaultText': instance.successDefaultText,
    };

TokenConfig _$TokenConfigFromJson(Map<String, dynamic> json) => TokenConfig(
      title: (json['title'] as String).replaceAll('\\n', '\n'),
      description: (json['description'] as String).replaceAll('\\n', '\n'),
      textFieldHintText: (json['textFieldHintText'] as String).replaceAll('\\n', '\n'),
      backButtonText: (json['backButtonText'] as String).replaceAll('\\n', '\n'),
      primaryButtonText: (json['primaryButtonText'] as String).replaceAll('\\n', '\n'),
    );

Map<String, dynamic> _$TokenConfigToJson(TokenConfig instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'textFieldHintText': instance.textFieldHintText,
      'backButtonText': instance.backButtonText,
      'primaryButtonText': instance.primaryButtonText,
    };
