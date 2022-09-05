import 'package:json_annotation/json_annotation.dart';
import 'package:odin/model/file_metadata.dart';

part 'files_metadata.g.dart';

/// Model class for the metadata received for a given token.
@JsonSerializable()
class FilesMetadata {
  FilesMetadata({
    this.basePath,
    this.files,
    this.totalFileSize,
  });

  final String? basePath;
  final List<FileMetadata>? files;
  final String? totalFileSize;

  factory FilesMetadata.fromJson(Map<String, dynamic> input) => _$FilesMetadataFromJson(input);

  Map<String, dynamic> toJson() => _$FilesMetadataToJson(this);
}
