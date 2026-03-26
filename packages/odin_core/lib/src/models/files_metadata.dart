import 'file_metadata.dart';

class FilesMetadata {
  FilesMetadata({this.basePath, this.files, this.totalFileSize});

  final String? basePath;
  final List<FileMetadata>? files;
  final String? totalFileSize;

  factory FilesMetadata.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    return FilesMetadata(
      basePath: json['basePath'] as String?,
      totalFileSize: json['totalFileSize'] as String?,
      files: rawFiles is List
          ? rawFiles
                .whereType<Map>()
                .map(
                  (item) => FileMetadata.fromJson(item.cast<String, dynamic>()),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'basePath': basePath,
    'files': files?.map((f) => f.toJson()).toList(),
    'totalFileSize': totalFileSize,
  };
}
