import 'package:dio/dio.dart';

class DocumentApiService {
  final Dio _dio;

  DocumentApiService(this._dio);

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final response = await _dio.get('/api/v1/documents/');
    if (response.statusCode == 200) {
      final List results = response.data['results'] ?? [];
      return results.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch documents');
  }

  Future<Map<String, dynamic>> fetchDocumentDetail(String uuid) async {
    final response = await _dio.get('/api/v1/documents/$uuid/');
    if (response.statusCode == 200) {
      return response.data;
    }
    throw Exception('Failed to fetch document detail');
  }

  Future<List<Map<String, dynamic>>> fetchDownloadHistory() async {
    final response = await _dio.get('/api/v1/documents/my-downloads/');
    if (response.statusCode == 200) {
      final List results = response.data['results'] ?? [];
      return results.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch download history');
  }

  Future<Response> downloadDocument(String uuid) async {
    return await _dio.get(
      '/api/v1/documents/$uuid/download/',
      options: Options(responseType: ResponseType.bytes),
    );
  }
}
