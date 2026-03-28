import 'dart:convert';

import 'file_metadata.dart';

class FilesMetadata {
  FilesMetadata({
    this.basePath,
    this.files,
    this.totalFileSize,
    this.originalTotalFileSize,
    this.fileCount,
    this.isArchive,
    this.originalFiles,
    this.downloadName,
  });

  final String? basePath;

  /// Server-side file list (may contain encrypted `.odin` filenames).
  final List<FileMetadata>? files;

  /// Encrypted container size as a string (e.g. "251").
  final String? totalFileSize;

  /// Original pre-encryption total file size (e.g. "11").
  final String? originalTotalFileSize;

  final int? fileCount;
  final bool? isArchive;

  /// Original pre-encryption file list from the server's `manifestPreview`.
  /// Use this for display when present.
  final List<FileMetadata>? originalFiles;

  /// Original top-level download filename from `manifestPreview.name`.
  final String? downloadName;

  /// Returns [originalFiles] when available, falling back to [files].
  List<FileMetadata>? get displayFiles => originalFiles ?? files;

  /// Returns [originalTotalFileSize] when available, falling back to [totalFileSize].
  String? get displayTotalFileSize => originalTotalFileSize ?? totalFileSize;

  factory FilesMetadata.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final serverFiles = rawFiles is List
        ? rawFiles
              .whereType<Map>()
              .map(
                (item) => FileMetadata.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
        : null;

    // Parse original filenames from manifestPreview — try several key names
    // since the server may use camelCase, snake_case, or just "manifest".
    List<FileMetadata>? originalFiles;
    String? downloadName;
    final rawManifest = json['manifestPreview'] ??
        json['manifest_preview'] ??
        json['manifest'];
    if (rawManifest != null) {
      Map<String, dynamic>? manifest;
      if (rawManifest is String) {
        try {
          manifest = (jsonDecode(rawManifest) as Map?)?.cast<String, dynamic>();
        } catch (_) {}
      } else if (rawManifest is Map) {
        manifest = rawManifest.cast<String, dynamic>();
      }
      if (manifest != null) {
        downloadName = manifest['name'] as String?;
        final rawOrigFiles = manifest['files'];
        if (rawOrigFiles is List) {
          originalFiles = rawOrigFiles
              .whereType<Map>()
              .map(
                (item) =>
                    FileMetadata.fromJson(item.cast<String, dynamic>()),
              )
              .toList();
        }
      }
    }

    // Parse originalTotalFileSize — prefer explicit field, fall back to
    // manifest['size'] which holds the pre-encryption total.
    String? originalTotalFileSize;
    final rawOrigSize =
        json['originalTotalFileSize'] ?? json['original_total_file_size'];
    if (rawOrigSize != null) {
      originalTotalFileSize = rawOrigSize.toString();
    }
    // Fallback: manifest['size'] contains the same value when the server
    // doesn't expose originalTotalFileSize directly.
    if (originalTotalFileSize == null) {
      final manifestSize =
          (json['manifestPreview'] is Map
              ? (json['manifestPreview'] as Map)['size']
              : null) ??
          (json['manifest'] is Map
              ? (json['manifest'] as Map)['size']
              : null);
      if (manifestSize != null) {
        originalTotalFileSize = manifestSize.toString();
      }
    }

    return FilesMetadata(
      basePath: json['basePath'] as String?,
      totalFileSize: json['totalFileSize'] as String?,
      originalTotalFileSize: originalTotalFileSize,
      fileCount: json['fileCount'] is int
          ? json['fileCount'] as int
          : int.tryParse('${json['fileCount']}'),
      isArchive: json['isArchive'] as bool?,
      files: serverFiles,
      originalFiles: originalFiles,
      downloadName: downloadName,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'basePath': basePath,
    'files': files?.map((f) => f.toJson()).toList(),
    'totalFileSize': totalFileSize,
    'fileCount': fileCount,
    'isArchive': isArchive,
  };
}
