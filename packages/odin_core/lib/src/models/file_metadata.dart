class FileMetadata {
  FileMetadata({this.path, this.size});

  final String? path;
  final int? size;

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    final rawSize = json['size'];
    return FileMetadata(
      path: json['path'] as String?,
      size: rawSize is int ? rawSize : int.tryParse('${json['size']}'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'size': size,
  };
}
