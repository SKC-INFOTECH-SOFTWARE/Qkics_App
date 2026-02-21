import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../documents/models/document_model.dart';
import '../documents/models/download_history_model.dart';
import '../documents/services/document_api_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentApiService api;

  DocumentProvider(this.api);

  List<Document> _documents = [];
  List<DownloadHistory> _downloadHistory = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<Document> get documents => _documents;
  List<DownloadHistory> get downloadHistory => _downloadHistory;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  bool _disposed = false;
  bool get mounted => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (mounted) super.notifyListeners();
  }

  Future<void> fetchDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await api.fetchDocuments();
      _documents = data.map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint(
        "Docs fetch failed (already handled globally if it was a Dio error): $e",
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Document?> fetchDocumentDetail(String uuid) async {
    try {
      final data = await api.fetchDocumentDetail(uuid);
      final detailedDoc = Document.fromJson(data);

      // Update the document in the list if it exists
      final index = _documents.indexWhere((doc) => doc.uuid == uuid);
      if (index != -1) {
        _documents[index] = detailedDoc;
        notifyListeners();
      }
      return detailedDoc;
    } catch (e) {
      debugPrint("Doc detail fetch failed: $e");
      return null;
    }
  }

 Future<void> fetchDownloadHistory() async {
  _isLoadingHistory = true;
  notifyListeners();

  try {
    _downloadHistory = await api.fetchDownloadHistory();
  } catch (e) {
    debugPrint("History fetch failed: $e");
  } finally {
    _isLoadingHistory = false;
    notifyListeners();
  }
}

  Future<String?> downloadDocument(Document doc) async {
    try {
      final response = await api.downloadDocument(doc.uuid);

      // Save to temporary directory or downloads
      final dir = await getApplicationDocumentsDirectory();
      // Clean filename
      final fileName = "${doc.title.replaceAll(RegExp(r'[^\w\s\-]'), '')}.pdf";
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(response.data);

      debugPrint("File downloaded to: $filePath");

      // Refresh history
      fetchDownloadHistory();

      return filePath;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final detail = e.response?.data['detail'] ?? "Download failed";
        throw detail;
      }
      rethrow;
    } catch (e) {
      debugPrint("Download failed: $e");
      rethrow;
    }
  }

  Future<String?> getLocalPath(String title) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "${title.replaceAll(RegExp(r'[^\w\s\-]'), '')}.pdf";
    final path = "${dir.path}/$fileName";
    final file = File(path);
    if (await file.exists()) {
      return path;
    }
    return null;
  }
}
