enum HistoryType {
  background,
  image,
  video,
  pdf;

  String get label {
    switch (this) {
      case HistoryType.background:
        return 'Suppression de fond';
      case HistoryType.image:
        return 'Compression image';
      case HistoryType.video:
        return 'Compression vidéo';
      case HistoryType.pdf:
        return 'Compression PDF';
    }
  }
}

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.originalName,
    required this.resultPath,
    required this.type,
    required this.createdAt,
    required this.originalSizeBytes,
    required this.resultSizeBytes,
  });

  final String id;
  final String originalName;
  final String resultPath;
  final HistoryType type;
  final DateTime createdAt;
  final int originalSizeBytes;
  final int resultSizeBytes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'resultPath': resultPath,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'originalSizeBytes': originalSizeBytes,
        'resultSizeBytes': resultSizeBytes,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        originalName: json['originalName'] as String,
        resultPath: json['resultPath'] as String,
        type: HistoryType.values.byName(json['type'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        originalSizeBytes: json['originalSizeBytes'] as int,
        resultSizeBytes: json['resultSizeBytes'] as int,
      );
}
