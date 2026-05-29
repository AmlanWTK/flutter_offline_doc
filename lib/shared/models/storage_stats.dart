class StorageStats {
  final int documentCount;
  final int imageBytes;
  final int textBytes;

  const StorageStats({
    required this.documentCount,
    required this.imageBytes,
    required this.textBytes,
  });

  int get totalBytes => imageBytes + textBytes;

  String get formattedTotal {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
