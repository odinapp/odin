// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'files_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilesMetadata _$FilesMetadataFromJson(Map<String, dynamic> json) =>
    FilesMetadata(
      basePath: json['basePath'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => FileMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalFileSize: json['totalFileSize'] as String?,
    );

Map<String, dynamic> _$FilesMetadataToJson(FilesMetadata instance) =>
    <String, dynamic>{
      'basePath': instance.basePath,
      'files': instance.files,
      'totalFileSize': instance.totalFileSize,
    };
