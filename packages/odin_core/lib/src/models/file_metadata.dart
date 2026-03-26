class FileMetadata {
  FileMetadata({this.path});

  final String? path;

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(path: json['path'] as String?);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'path': path};
}
