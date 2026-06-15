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

  Future<void> fetchDocuments({
    String? search,
    String? accessType,
    bool? isActive,
    String? ordering,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await api.fetchDocuments(
        search: search,
        accessType: accessType,
        isActive: isActive,
        ordering: ordering,
      );
      final List results = data['results'] ?? [];
      _documents = results.map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint("Docs fetch failed: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Document?> fetchDocumentDetail(String? uuid) async {
    if (uuid == null) return null;
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
      final data = await api.fetchDownloadHistory();
      final List results = data['results'] ?? [];
      _downloadHistory = results
          .map((e) => DownloadHistory.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint("History fetch failed: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<String?> downloadDocument(Document doc) async {
    if (doc.uuid == null) {
      throw "Document ID is missing";
    }
    try {
      final response = await api.downloadDocument(doc.uuid!);

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

  List<Document> _myDocuments = [];
  bool _isLoadingMyDocs = false;

  List<Document> get myDocuments => _myDocuments;
  bool get isLoadingMyDocs => _isLoadingMyDocs;

  Future<void> fetchMyDocuments({
    String? search,
    String? accessType,
    bool? isActive,
    String? ordering,
  }) async {
    _isLoadingMyDocs = true;
    notifyListeners();

    try {
      final data = await api.fetchMyDocuments(
        search: search,
        accessType: accessType,
        isActive: isActive,
        ordering: ordering,
      );
      final List results = data['results'] ?? [];
      _myDocuments = results.map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint("My docs fetch failed: $e");
    } finally {
      _isLoadingMyDocs = false;
      notifyListeners();
    }
  }

  Future<void> uploadDocument({
    required String title,
    required String description,
    required String filePath,
    required String accessType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await api.uploadDocument(
        title: title,
        description: description,
        filePath: filePath,
        accessType: accessType,
      );
      // Refresh my documents after successful upload
      await fetchMyDocuments();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final List? errors = e.response?.data;
        if (errors != null && errors.isNotEmpty) {
          throw errors.first.toString();
        }
      }
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDocument(
    String uuid, {
    String? accessType,
    bool? isActive,
  }) async {
    try {
      await api.updateMyDocument(
        uuid,
        accessType: accessType,
        isActive: isActive,
      );
      // Refresh both lists to be safe
      await fetchDocuments();
      await fetchMyDocuments();
    } catch (e) {
      debugPrint("Update doc failed: $e");
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
