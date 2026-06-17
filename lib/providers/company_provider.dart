import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:q_kics/models/company.dart';
import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/providers/api_provider.dart';

class CompanyPostPaymentRequiredException implements Exception {
  final double price;

  const CompanyPostPaymentRequiredException({required this.price});

  @override
  String toString() => 'Payment required: $price';
}

class CompanyProvider with ChangeNotifier {
  final ApiProvider apiProvider;

  CompanyProvider({required this.apiProvider});

  Dio get _dio => apiProvider.dio;

  // State
  List<Company> _myCompanies = [];
  bool _isLoadingMyCompanies = false;

  List<Company> _publicCompanies = [];
  bool _isLoadingPublicCompanies = false;

  List<CompanyPost> _globalPosts = [];
  String? _nextGlobalPostsCursor;
  bool _isLoadingGlobalPosts = false;
  bool _hasMoreGlobalPosts = true;

  // Getters
  List<Company> get myCompanies => _myCompanies;
  bool get isLoadingMyCompanies => _isLoadingMyCompanies;

  List<Company> get publicCompanies => _publicCompanies;
  bool get isLoadingPublicCompanies => _isLoadingPublicCompanies;

  List<CompanyPost> get globalPosts => _globalPosts;
  bool get isLoadingGlobalPosts => _isLoadingGlobalPosts;
  bool get hasMoreGlobalPosts => _hasMoreGlobalPosts;

  List<dynamic> _extractResults(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) return results;
    }
    if (data is Map) {
      final results = data['results'];
      if (results is List) return results;
    }
    return [];
  }

  FormData _buildCompanyPostFormData(Map<String, dynamic> data) {
    final formData = FormData();

    data.forEach((key, value) {
      if (value == null) return;

      if ((key == 'uploaded_files' || key == 'uploaded_files[]') &&
          value is List) {
        for (final item in value) {
          if (item is MultipartFile) {
            formData.files.add(MapEntry('uploaded_files', item));
          }
        }
        return;
      }

      if (value is List) {
        for (final item in value) {
          formData.fields.add(MapEntry(key, item.toString()));
        }
        return;
      }

      formData.fields.add(MapEntry(key, value.toString()));
    });

    return formData;
  }

  // COMPANY ENDPOINTS
  Future<Company?> createCompany(Map<String, dynamic> data) async {
    try {
      FormData formData = FormData.fromMap(data);

      final response = await _dio.post(
        "/api/v1/companies/",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Company newCompany = Company.fromJson(response.data);
        _myCompanies.insert(0, newCompany);
        notifyListeners();
        return newCompany;
      }
    } on DioException catch (e) {
      debugPrint("Error creating company (DioException): ${e.response?.data}");
      rethrow;
    } catch (e) {
      debugPrint("Error creating company: $e");
      rethrow;
    }
    return null;
  }

  Future<void> fetchMyCompanies() async {
    _isLoadingMyCompanies = true;
    notifyListeners();

    try {
      final response = await _dio.get("/api/v1/companies/my/");
      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'] ?? [];
        _myCompanies = results.map((json) => Company.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching my companies: $e");
    } finally {
      _isLoadingMyCompanies = false;
      notifyListeners();
    }
  }

  Future<void> fetchCompanyList() async {
    _isLoadingPublicCompanies = true;
    notifyListeners();

    try {
      final response = await _dio.get("/api/v1/companies/list/");
      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'] ?? [];
        _publicCompanies = results.map((json) => Company.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching public companies: $e");
    } finally {
      _isLoadingPublicCompanies = false;
      notifyListeners();
    }
  }

  Future<Company?> fetchCompanyDetails(String slug) async {
    try {
      final response = await _dio.get("/api/v1/companies/$slug/");
      if (response.statusCode == 200) {
        return Company.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Error fetching company details: $e");
    }
    return null;
  }

  Future<Company?> updateCompany(String uuid, Map<String, dynamic> data) async {
    try {
      FormData formData = FormData.fromMap(data);
      
      final response = await _dio.patch(
        "/api/v1/companies/$uuid/update/",
        data: formData,
      );

      if (response.statusCode == 200) {
        Company updated = Company.fromJson(response.data);
        
        final myIndex = _myCompanies.indexWhere((c) => c.id == updated.id);
        if (myIndex != -1) _myCompanies[myIndex] = updated;

        final publicIndex = _publicCompanies.indexWhere((c) => c.id == updated.id);
        if (publicIndex != -1) _publicCompanies[publicIndex] = updated;

        notifyListeners();
        return updated;
      }
    } on DioException catch (e) {
      debugPrint("Error updating company (DioException): ${e.response?.data}");
      rethrow;
    } catch (e) {
      debugPrint("Error updating company: $e");
      rethrow;
    }
    return null;
  }

  Future<bool> deleteCompany(String uuid) async {
    try {
      final response = await _dio.delete("/api/v1/companies/$uuid/delete/");
      if (response.statusCode == 204 || response.statusCode == 200) {
        _myCompanies.removeWhere((c) => c.id == uuid);
        _publicCompanies.removeWhere((c) => c.id == uuid);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting company: \$e");
    }
    return false;
  }

  // COMPANY POST ENDPOINTS
  Future<CompanyPost?> createCompanyPost(
    String companyId,
    Map<String, dynamic> data,
  ) async {
    try {
      final formData = _buildCompanyPostFormData(data);
      final response = await _dio.post(
        "/api/v1/companies/$companyId/posts/create/",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data is Map &&
            response.data['payment_required'] == true) {
          throw CompanyPostPaymentRequiredException(
            price:
                double.tryParse(response.data['price']?.toString() ?? '0') ?? 0,
          );
        }
        debugPrint("Company post created: ${response.data}");
        CompanyPost newPost = CompanyPost.fromJson(response.data);
        _globalPosts.insert(0, newPost);
        notifyListeners();
        return newPost;
      }
    } catch (e) {
      debugPrint("Error creating company post: $e");
      rethrow;
    }
    return null;
  }

  Future<List<CompanyPost>> fetchCompanyPosts(String companyId) async {
    try {
      final response = await _dio.get("/api/v1/companies/$companyId/posts/");
      debugPrint("Company posts: ${response.data}");
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(response.data);
        return results.map((json) => CompanyPost.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching posts for company: $e");
    }
    return [];
  }

  Future<void> fetchAllCompanyPosts({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _globalPosts.clear();
      _nextGlobalPostsCursor = null;
      _hasMoreGlobalPosts = true;
    }

    if (_isLoadingGlobalPosts || !_hasMoreGlobalPosts) return;

    _isLoadingGlobalPosts = true;
    notifyListeners();

    try {
      String url = "/api/v1/companies/posts/";
      if (!forceRefresh && _nextGlobalPostsCursor != null) {
        url = _nextGlobalPostsCursor!;
      }

      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(response.data);
        final newPosts = results.map((json) => CompanyPost.fromJson(json)).toList();

        if (forceRefresh) {
          _globalPosts = newPosts;
        } else {
          _globalPosts.addAll(newPosts);
        }

        _nextGlobalPostsCursor = response.data is Map<String, dynamic>
            ? response.data['next'] as String?
            : null;
        _hasMoreGlobalPosts = _nextGlobalPostsCursor != null;
      }
    } catch (e) {
      debugPrint("Error fetching all company posts: $e");
    } finally {
      _isLoadingGlobalPosts = false;
      notifyListeners();
    }
  }

  Future<CompanyPost?> updateCompanyPost(String postId, Map<String, dynamic> data) async {
    try {
      final formData = _buildCompanyPostFormData(data);
      final response = await _dio.patch(
        "/api/v1/companies/posts/$postId/update/",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );

      if (response.statusCode == 200) {
        CompanyPost updated = CompanyPost.fromJson(response.data);
        
        final idx = _globalPosts.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          _globalPosts[idx] = updated;
          notifyListeners();
        }
        return updated;
      }
    } catch (e) {
      debugPrint("Error updating company post: $e");
    }
    return null;
  }

  Future<bool> deleteCompanyPost(String postId) async {
    try {
      final response = await _dio.delete("/api/v1/companies/posts/$postId/delete/");
      if (response.statusCode == 204 || response.statusCode == 200) {
        _globalPosts.removeWhere((p) => p.id == postId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting company post: $e");
    }
    return false;
  }

  // COMPANY MEMBERS ENDPOINTS
  Future<List<CompanyMember>> fetchCompanyMembers(String companyId) async {
    try {
      final response = await _dio.get("/api/v1/companies/$companyId/members/");
      if (response.statusCode == 200) {
        final List<dynamic> results = response.data is List ? response.data : (response.data['results'] ?? []);
        return results.map((json) => CompanyMember.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching company members: $e");
    }
    return [];
  }

  Future<CompanyMember?> addCompanyMember(String companyId, String userId) async {
    try {
      final response = await _dio.post(
        "/api/v1/companies/$companyId/members/add/",
        data: {"user_id": userId},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return CompanyMember.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Error adding company member: $e");
    }
    return null;
  }

  Future<bool> removeCompanyMember(String companyId, String userId) async {
    try {
      final response = await _dio.delete(
        "/api/v1/companies/$companyId/members/$userId/remove/"
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("Error removing company member: $e");
    }
    return false;
  }
}
