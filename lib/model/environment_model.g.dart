// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Environment _$EnvironmentFromJson(Map<String, dynamic> json) => Environment(
      json['API_URL'] as String,
      json['API_VERSION'] as String,
      json['SUCCESSFUL_STATUS_CODE'] as String,
    );

Map<String, dynamic> _$EnvironmentToJson(Environment instance) =>
    <String, dynamic>{
      'API_URL': instance.API_URL,
      'API_VERSION': instance.API_VERSION,
      'SUCCESSFUL_STATUS_CODE': instance.SUCCESSFUL_STATUS_CODE,
    };
