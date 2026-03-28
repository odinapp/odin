class PendingUpload {
  PendingUpload({
    required this.id,
    required this.shareToken,
    required this.deleteUrl,
    required this.expiresAt,
    required this.createdAt,
    this.fileSummary,
  });

  final String id;
  final String shareToken;
  final String deleteUrl;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? fileSummary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'shareToken': shareToken,
    'deleteUrl': deleteUrl,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    if (fileSummary != null) 'fileSummary': fileSummary,
  };

  factory PendingUpload.fromJson(Map<String, dynamic> j) {
    return PendingUpload(
      id: j['id'] as String,
      shareToken: j['shareToken'] as String,
      deleteUrl: j['deleteUrl'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(j['expiresAt'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      fileSummary: j['fileSummary'] as String?,
    );
  }
}
