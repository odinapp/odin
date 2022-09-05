import 'package:json_annotation/json_annotation.dart';

part 'file_metadata.g.dart';

/// Model class for the metadata received for a given token.
@JsonSerializable()
class FileMetadata {
  FileMetadata({
    this.path,
  });

  final String? path;

  factory FileMetadata.fromJson(Map<String, dynamic> input) => _$FileMetadataFromJson(input);

  Map<String, dynamic> toJson() => _$FileMetadataToJson(this);
}
