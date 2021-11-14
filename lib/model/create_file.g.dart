// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateFile _$CreateFileFromJson(Map<String, dynamic> json) => CreateFile(
      path: json['path'] as String?,
      content: json['content'] as String?,
      message: json['message'] as String?,
      branch: json['branch'] as String?,
      committer: json['committer'] == null
          ? null
          : CommitUser.fromJson(json['committer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateFileToJson(CreateFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'message': instance.message,
      'content': instance.content,
      'branch': instance.branch,
      'committer': instance.committer,
    };
