class DownloadHistory {
  final String documentTitle;
  final String accessTypeSnapshot;
  final DateTime downloadedAt;

  DownloadHistory({
    required this.documentTitle,
    required this.accessTypeSnapshot,
    required this.downloadedAt,
  });

  factory DownloadHistory.fromJson(Map<String, dynamic> json) {
    return DownloadHistory(
      documentTitle: json['document_title'] ?? '',
      accessTypeSnapshot: json['access_type_snapshot'] ?? '',
      downloadedAt: DateTime.parse(
        json['downloaded_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
