import 'package:dio/dio.dart';

class DocumentApiService {
  final Dio _dio;

  DocumentApiService(this._dio);

  Future<Map<String, dynamic>> fetchDocuments({
    String? search,
    String? accessType,
    bool? isActive,
    String? ordering,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (search != null) queryParameters['search'] = search;
    if (accessType != null) queryParameters['access_type'] = accessType;
    if (isActive != null) queryParameters['is_active'] = isActive;
    if (ordering != null) queryParameters['ordering'] = ordering;

    final response = await _dio.get(
      '/api/v1/documents/',
      queryParameters: queryParameters,
    );
    if (response.statusCode == 200) {
      return response.data;
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

  Future<Map<String, dynamic>> fetchMyDocuments({
    String? search,
    String? accessType,
    bool? isActive,
    String? ordering,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (search != null) queryParameters['search'] = search;
    if (accessType != null) queryParameters['access_type'] = accessType;
    if (isActive != null) queryParameters['is_active'] = isActive;
    if (ordering != null) queryParameters['ordering'] = ordering;

    final response = await _dio.get(
      '/api/v1/documents/my-documents/',
      queryParameters: queryParameters,
    );
    if (response.statusCode == 200) {
      return response.data;
    }
    throw Exception('Failed to fetch my documents');
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String title,
    required String description,
    required String filePath,
    required String accessType,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'access_type': accessType,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/v1/documents/upload/',
      data: formData,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data;
    }
    throw Exception('Failed to upload document');
  }

  Future<Map<String, dynamic>> updateMyDocument(
    String uuid, {
    String? accessType,
    bool? isActive,
  }) async {
    final Map<String, dynamic> data = {};
    if (accessType != null) data['access_type'] = accessType;
    if (isActive != null) data['is_active'] = isActive;

    final response = await _dio.patch(
      '/api/v1/documents/my-documents/', // Suggestion: Is this correct? Usually it would be /uuid/
      // The user spec said: Update My Document /api/v1/documents/my-documents/ PATCH
      // I'll follow the spec.
      data: data,
    );
    if (response.statusCode == 200) {
      return response.data;
    }
    throw Exception('Failed to update document');
  }

  Future<Map<String, dynamic>> fetchDownloadHistory() async {
    final response = await _dio.get('/api/v1/documents/my-downloads/');

    if (response.statusCode == 200) {
      return response.data;
    }

    throw Exception("Failed to fetch download history");
  }

  Future<Response> downloadDocument(String uuid) async {
    return await _dio.get(
      '/api/v1/documents/$uuid/download/',
      options: Options(responseType: ResponseType.bytes),
    );
  }
}
