// lib/providers/api_provider.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:q_kics/models/comment.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/models/tag.dart';
import 'package:q_kics/models/user.dart';
import 'package:q_kics/Network/global_error_handler.dart';
import 'package:q_kics/Network/server_response_page.dart';

class ApiProvider with ChangeNotifier {
  // Singleton
  static final ApiProvider _instance = ApiProvider._internal();
  factory ApiProvider() => _instance;
  ApiProvider._internal();

  // Core
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  CookieJar? _cookieJar;
  List<Comment> _comments = [];
  List<Comment> get comments => _comments;
  int? _currentPostId;

  List<Post> _searchResults = [];
  List<Post> get searchResults => _searchResults;

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  String? _nextCommentCursor;
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;

  bool get isLoadingComments => _isLoadingComments;
  bool get hasMoreComments => _hasMoreComments;
  // Auth state
  String? _accessToken;
  User? _currentUser;
  List<Post> _posts = [];

  // Public getters
  Dio get dio => _dio;
  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  User? get currentUser => _currentUser;
  List<Post> get posts => _posts;

  String? _nextCursor;
  String? _previousCursor;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _selectedTag;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get selectedTag => _selectedTag;
  bool mounted = true;

  // For robust token refresh
  bool _isRefreshing = false;
  Future<bool>? _refreshCompleter;

  @override
  void dispose() {
    mounted = false;
    super.dispose();
  }

  // Call this to add a newly created post at the top (optimistic UI)
  void addPostToTop(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  // Initialize Dio + Cookies + Load saved token
  Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: "http://192.168.0.114:1000",
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      ),
    );

    // Setup persistent cookie jar (required for HTTP-Only refresh token)
    final appDir = await getApplicationDocumentsDirectory();
    final cookiePath = "${appDir.path}/.cookies/";
    _cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    _dio.interceptors.add(CookieManager(_cookieJar!));

    // Restore access token from secure storage
    _accessToken = await _storage.read(key: 'access_token');

    _setupInterceptors();
    notifyListeners();
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(CookieManager(_cookieJar!));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          final request = e.requestOptions;

          // Handle 401 Unauthorized errors
          if (e.response?.statusCode == 401 && _accessToken != null) {
            // Check if we are already refreshing the token
            if (_isRefreshing) {
              // Wait for the existing refresh process to complete
              final success = await _refreshCompleter;
              if (success == true) {
                // Retry the original request with the new token
                request.headers['Authorization'] = 'Bearer $_accessToken';
                try {
                  final clone = await _dio.fetch(request);
                  return handler.resolve(clone);
                } catch (err) {
                  return handler.next(e);
                }
              }
            } else {
              // Start a new refresh process
              if (await _refreshAccessToken()) {
                request.headers['Authorization'] = 'Bearer $_accessToken';
                try {
                  final clone = await _dio.fetch(request);
                  return handler.resolve(clone);
                } catch (err) {
                  return handler.next(e);
                }
              } else {
                // Refresh failed, logout and handle error
                await logout();
                GlobalErrorHandler.show(AppErrorType.unauthorized);
                return handler.next(e);
              }
            }
          }

          // Global Error Handling for other types
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            GlobalErrorHandler.show(AppErrorType.timeout);
          } else if (e.type == DioExceptionType.connectionError) {
            // 🛑 Distinguish between "No Internet" and "Server Refused" (Server Stopped)
            final errorStr = e.error?.toString().toLowerCase() ?? "";
            final msgStr = e.message?.toLowerCase() ?? "";

            if (errorStr.contains("refused") || msgStr.contains("refused")) {
              GlobalErrorHandler.show(AppErrorType.serverDown);
            } else {
              GlobalErrorHandler.show(AppErrorType.noInternet);
            }
          } else if (e.response?.statusCode != null &&
              e.response!.statusCode! >= 500) {
            GlobalErrorHandler.show(AppErrorType.serverDown);
          }

          handler.next(e);
        },
      ),
    );
  }

  // Refresh token is sent automatically via HTTP-Only cookie
  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) return _refreshCompleter ?? Future.value(false);

    _isRefreshing = true;
    _refreshCompleter = _performRefresh();

    final success = await _refreshCompleter;

    _isRefreshing = false;
    _refreshCompleter = null;

    return success ?? false;
  }

  Future<bool> _performRefresh() async {
    try {
      // Use a fresh Dio instance or dedicated call to avoid interceptor recursion if needed
      // However, since we check _isRefreshing at the start of _refreshAccessToken,
      // recursive calls to refresh will just return the existing completer.
      final response = await _dio.post("/api/v1/auth/token/refresh/");

      if (response.statusCode == 200) {
        _accessToken = response.data['access'] as String;
        await _storage.write(key: 'access_token', value: _accessToken);
        _currentUser = null; // Force reload user on next access
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      debugPrint("Token refresh failed: ${e.response?.data}");
    } catch (e) {
      debugPrint("Refresh error: $e");
    }
    return false;
  }

  // Login – backend sets HTTP-Only refresh cookie
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        "/api/v1/auth/login/",
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access'];
        await _storage.write(key: 'access_token', value: _accessToken);
        _currentUser = null; // Will be fetched fresh
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login failed: $e");
    }
    return false;
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String password2,
    required String email,
    required String phone,
    String userType = "normal",
  }) async {
    try {
      final response = await _dio.post(
        "/api/v1/auth/register/",
        data: {
          "username": username,
          "password": password,
          "password2": password2,
          "email": email,
          "phone": phone,
          "user_type": userType,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          "success": true,
          "message": response.data["message"] ?? "Registered successfully",
        };
      }
      return {"success": false, "message": "Registration failed"};
    } on DioException catch (e) {
      String msg = "Registration failed";
      if (e.response?.data is Map) {
        final errors = e.response!.data as Map<String, dynamic>;
        final firstError = errors.values.first;
        msg = firstError is List ? firstError.first : firstError.toString();
      }
      return {"success": false, "message": msg};
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // Fetch current authenticated user
  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUser != null) {
      return _currentUser;
    }

    try {
      final response = await _dio.get("/api/v1/auth/me/");

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
        notifyListeners();
        return _currentUser;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return getCurrentUser(forceRefresh: true);
        }
      }
      debugPrint("Failed to fetch user: $e");
    } catch (e) {
      debugPrint("User fetch error: $e");
    }

    return null;
  }

  // Logout – clear everything
  Future<void> logout() async {
    try {
      await _dio.post(
        "/api/v1/auth/logout/",
      ); // Optional: blacklist refresh token
    } catch (_) {}

    await _storage.delete(key: 'access_token');
    _accessToken = null;
    _currentUser = null;

    // Delete all cookies (including HTTP-Only refresh token)
    await _cookieJar?.deleteAll();
    notifyListeners();
  }

  // Add to ApiProvider

  Future<void> fetchPosts({bool forceRefresh = false, String? tag}) async {
    if (forceRefresh) {
      _posts.clear();
      _nextCursor = null;
      _previousCursor = null;
      _hasMore = true;
      if (tag != null) {
        _selectedTag = tag;
      }

      // SAFE: Defer notifyListeners until after build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifyListeners();
      });
    }

    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;

    // Also defer this notify if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) notifyListeners();
    });

    try {
      String url = "/api/v1/community/posts/";
      Map<String, dynamic> queryParameters = {};

      if (_selectedTag != null) {
        url = "/api/v1/community/search/";
        queryParameters['q'] = "$_selectedTag";
      } else if (!forceRefresh && _nextCursor != null) {
        url = _nextCursor!;
      }

      final response = await _dio.get(url, queryParameters: queryParameters);

      if (response.statusCode == 200) {
        List<Post> newPosts = [];
        if (_selectedTag != null) {
          // Search returns a flat list of posts
          final List<dynamic> results = response.data;
          newPosts = results
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();
          _nextCursor = null;
          _previousCursor = null;
          _hasMore = false;
        } else {
          // Normal posts are paginated
          final jsonResponse = response.data as Map<String, dynamic>;
          final List<dynamic> results = jsonResponse['results'];

          newPosts = results
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();

          _nextCursor = jsonResponse['next'] as String?;
          _previousCursor = jsonResponse['previous'] as String?;
          _hasMore = _nextCursor != null;
        }

        if (forceRefresh) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }

        // SAFE: Notify after data is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return fetchPosts(forceRefresh: forceRefresh);
      }
      debugPrint("Error fetching posts: $e");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    } finally {
      _isLoadingMore = false;
      // Final safe notify
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifyListeners();
      });
    }
  }

  // Clear tag filter
  Future<void> clearTag() async {
    _selectedTag = null;
    await fetchPosts(forceRefresh: true);
  }

  // Optional: Load older posts from the top (for pull-to-refresh upward)
  Future<void> fetchPreviousPosts() async {
    if (_previousCursor == null || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _dio.get(_previousCursor!);
      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        final List<Post> olderPosts = (jsonResponse['results'] as List)
            .map((json) => Post.fromJson(json))
            .toList();

        _posts.insertAll(0, olderPosts);
        _nextCursor = jsonResponse['next'];
        _previousCursor = jsonResponse['previous'];
        _hasMore = _nextCursor != null;

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading previous posts: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────
  // COMMENTS & REPLIES – FINAL & PERFECT VERSION
  // ────────────────────────────────────────

  void setCurrentPostId(int postId) {
    _currentPostId = postId;
  }

  // 1. Top-level comments only (no replies)
  Future<void> fetchComments(int postId, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _comments.clear();
      _nextCommentCursor = null;
      _hasMoreComments = true;
    }

    if (_isLoadingComments || !_hasMoreComments) return;

    _isLoadingComments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

    try {
      String url = "/api/v1/community/posts/$postId/comments/";
      if (!forceRefresh && _nextCommentCursor != null) {
        url = _nextCommentCursor!;
      }

      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final json = response.data;
        final List<dynamic> results = json['results'];
        final newComments = results.map((j) => Comment.fromJson(j)).toList();
        print("Post Id $postId ");
        if (forceRefresh) {
          _comments = newComments;
        } else {
          _comments.addAll(newComments);
        }

        _nextCommentCursor = json['next'];
        _hasMoreComments = _nextCommentCursor != null;

        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      }
    } catch (e) {
      debugPrint("fetchComments error: $e");
    } finally {
      _isLoadingComments = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  // fetchReplies with pagination (same structure)
  Future<void> fetchReplies(int commentId) async {
    try {
      final response = await _dio.get(
        "/api/v1/community/comments/$commentId/replies/",
      );
      if (response.statusCode == 200) {
        final json = response.data;
        final List<dynamic> results = json['results'];
        final newReplies = results.map((j) => Comment.fromJson(j)).toList();

        void inject(List<Comment> list) {
          for (var c in list) {
            if (c.id == commentId) {
              c.replies = newReplies;
              return;
            }
            if (c.replies.isNotEmpty) inject(c.replies);
          }
        }

        inject(_comments);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("fetchReplies error: $e");
    }
  }

  /// Add new comment
  Future<bool> addComment(int postId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      final previewContent = content.length > 300
          ? content.substring(0, 300)
          : content;
      final response = await _dio.post(
        "/api/v1/community/posts/$postId/comments/",
        data: {
          "preview_content": previewContent,
          "full_content": content.trim(),
        },
      );
      if (response.statusCode == 201) {
        await fetchComments(postId, forceRefresh: true);
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final ok = await _refreshAccessToken();
        if (ok) return addComment(postId, content);
      }
    }
    return false;
  }

  /// ADD REPLY — Only to top-level comments (your backend requirement)
  Future<bool> addReply(int commentId, String content) async {
    try {
      final previewContent = content.length > 300
          ? content.substring(0, 300)
          : content;
      final response = await _dio.post(
        "/api/v1/community/comments/$commentId/replies/",
        data: {
          "preview_content": previewContent,
          "full_content": content.trim(),
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("addReply failed: $e");
      return false;
    }
  }

  /// Update comment/reply
  Future<bool> updateComment(int commentId, int postId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      final previewContent = content.length > 300
          ? content.substring(0, 300)
          : content;
      final response = await _dio.put(
        "/api/v1/community/comments/$commentId/",
        data: {
          "preview_content": previewContent,
          "full_content": content.trim(),
        },
      );
      if (response.statusCode == 200) {
        await fetchComments(postId, forceRefresh: true);
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final ok = await _refreshAccessToken();
        if (ok) return updateComment(commentId, postId, content);
      }
    }
    return false;
  }

  /// Update reply (same endpoint pattern)
  Future<bool> updateReply(int replyId, String content) async {
    return updateComment(replyId, _currentPostId ?? 0, content);
  }

  /// Delete comment
  Future<bool> deleteComment(int commentId, int postId) async {
    try {
      final response = await _dio.delete(
        "/api/v1/community/comments/$commentId/",
      );
      if (response.statusCode == 204) {
        await fetchComments(postId, forceRefresh: true);
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final ok = await _refreshAccessToken();
        if (ok) return deleteComment(commentId, postId);
      }
    }
    return false;
  }

  /// Delete reply
  Future<bool> deleteReply(int replyId) async {
    if (_currentPostId == null) return false;
    return deleteComment(replyId, _currentPostId!);
  }

  // Toggle Like on Post
  Future<void> togglePostLike(int postId) async {
    try {
      final response = await _dio.post("/api/v1/community/posts/$postId/like/");
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final updatedPost = Post.fromJson(data);

        // Update posts list me
        _posts = _posts.map((p) {
          if (p.id == postId) {
            return updatedPost;
          }
          return p;
        }).toList();

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Post like error: $e");
    }
  }

  // Toggle Like on Comment (works for both comment & reply)
  Future<void> toggleCommentLike(int commentId) async {
    try {
      final response = await _dio.post(
        "/api/v1/community/comments/$commentId/like/",
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final updatedComment = Comment.fromJson(data);

        // Find and update in tree
        void updateInTree(List<Comment> comments) {
          for (int i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
              comments[i] = updatedComment;
              return;
            }
            if (comments[i].replies.isNotEmpty) {
              updateInTree(comments[i].replies);
            }
          }
        }

        updateInTree(_comments);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Comment like error: $e");
    }
  }

  // Inside your ApiProvider class
  // CREATE POST — MULTIPLE TAGS FIXED
  Future<bool> createPost({
    String? title,
    required String previewContent,
    required String fullContent,
    File? image,
    List<String> tags = const [],
  }) async {
    try {
      // Convert tag names → tag IDs
      final List<int> tagIds = await _getTagIds(tags);

      final Map<String, dynamic> data = {
        'preview_content': previewContent,
        'full_content': fullContent,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (tagIds.isNotEmpty) 'tags': tagIds,
      };

      FormData? formData;
      if (image != null) {
        formData = FormData.fromMap({
          ...data,
          'image': await MultipartFile.fromFile(image.path),
        });
      }

      final response = await _dio.post(
        '/api/v1/community/posts/',
        data: formData ?? data,
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Create post error: $e");
      return false;
    }
  }

  // YE HELPER FUNCTION ADD KAR DE ApiProvider MEIN
  Future<List<int>> _getTagIds(List<String> tagNames) async {
    if (tagNames.isEmpty) return [];

    try {
      final response = await _dio.get('/api/v1/community/tags/');
      if (response.statusCode == 200) {
        final List<dynamic> allTags = response.data;
        final Map<String, int> tagMap = {
          for (var tag in allTags)
            tag['name'].toString().toLowerCase(): tag['id'] as int,
        };

        return tagNames
            .map((name) => tagMap[name.toLowerCase().trim()])
            .where((id) => id != null)
            .cast<int>()
            .toList();
      }
    } catch (e) {
      debugPrint("Tag fetch error: $e");
    }
    return [];
  }

  Future<List<Tag>> fetchAllTags() async {
    try {
      final response = await _dio.get('/api/v1/community/tags/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Tag.fromJson(json)).toList();
      } else {
        debugPrint('Fetch tags failed: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('Dio error fetching tags: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error fetching tags: $e');
      return [];
    }
  }

  // UPDATE POST — MULTIPLE TAGS FIXED
  Future<bool> updatePost({
    required int postId,
    String? title,
    required String previewContent,
    required String fullContent,
    File? image,
    bool removeImage = false,
    List<String> tags = const [],
  }) async {
    try {
      final List<int> tagIds = await _getTagIds(tags);

      final Map<String, dynamic> data = {
        'preview_content': previewContent,
        'full_content': fullContent,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (tagIds.isNotEmpty) 'tags': tagIds,
      };

      FormData? formData;
      if (removeImage) {
        formData = FormData.fromMap({...data, 'image': ''});
      } else if (image != null) {
        formData = FormData.fromMap({
          ...data,
          'image': await MultipartFile.fromFile(image.path),
        });
      }

      final response = await _dio.put(
        '/api/v1/community/posts/$postId/',
        data: formData ?? data,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Update post error: $e");
      return false;
    }
  }

  /// FETCH SINGLE POST FOR EDITING
  Future<Post?> fetchSinglePost(int postId) async {
    try {
      final response = await _dio.get('/api/v1/community/posts/$postId/');

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        return Post.fromJson(json); // ← tera existing fromJson use karega
      }
    } on DioException catch (e) {
      debugPrint("Fetch single post error: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
    return null;
  }

  /// DELETE POST
  /// DELETE /api/v1/community/posts/<post_id>/
  Future<bool> deletePost(int postId) async {
    try {
      final response = await _dio.delete('/api/v1/community/posts/$postId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Successfully deleted
        return true;
      } else {
        debugPrint("Delete failed: ${response.statusCode} ${response.data}");
        return false;
      }
    } on DioException catch (e) {
      debugPrint("Delete post error: ${e.response?.data ?? e.message}");
      return false;
    } catch (e) {
      debugPrint("Unexpected delete error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchEntrepreneurProfile() async {
    try {
      final response = await _dio.get('/api/v1/entrepreneurs/me/profile/');
      return response.data is Map<String, dynamic> ? response.data : null;
    } catch (e) {
      debugPrint("Entrepreneur profile error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchExpertProfile() async {
    try {
      final response = await _dio.get('/api/v1/experts/me/profile/');
      return response.data is Map<String, dynamic> ? response.data : null;
    } catch (e) {
      debugPrint("Expert profile error: $e");
      return null;
    }
  }

  Future<List<Post>> fetchUserPostsByUsername(String username) async {
    try {
      final response = await _dio.get(
        '/api/v1/community/posts/user/$username/',
      );

      if (response.statusCode == 200) {
        // The actual data is inside the "results" key
        final Map<String, dynamic> jsonResponse =
            response.data as Map<String, dynamic>;
        final List<dynamic> results = jsonResponse['results'] as List<dynamic>;

        return results
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint("Failed to fetch posts: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching user posts by username ($username): $e");
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────
  // EXPERT PROFILE FUNCTIONS
  // ──────────────────────────────────────────────────────────────
  Future<void> createExpertProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/v1/experts/me/profile/',
        data: data,
      );
      debugPrint("Expert profile saved successfully: ${response.statusCode}");
    } on DioException catch (e) {
      String errorMsg = "Failed to save Expert profile";
      if (e.response != null) {
        errorMsg +=
            " | Status: ${e.response?.statusCode} | Data: ${e.response?.data}";
        debugPrint("Expert Profile Save Error: $errorMsg");
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg += " | Connection timeout";
        debugPrint("Expert Profile Timeout: $e");
      } else if (e.type == DioExceptionType.badResponse) {
        errorMsg += " | Bad response";
      } else {
        errorMsg += " | Network error: ${e.message}";
        debugPrint("Expert Profile Network Error: $e");
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint("Unexpected error in createExpertProfile: $e");
      throw Exception("An unexpected error occurred while saving profile");
    }
  }

  Future<void> submitExpertForReview({String note = ""}) async {
    try {
      final response = await _dio.post(
        '/api/v1/experts/me/submit/',
        data: {"note": note},
      );
      debugPrint(
        "Expert application submitted successfully: ${response.statusCode}",
      );
    } on DioException catch (e) {
      String errorMsg = "Failed to submit Expert application";
      if (e.response != null) {
        final data = e.response?.data;
        errorMsg += " | Status: ${e.response?.statusCode}";
        if (data is Map && data.containsKey('detail')) {
          errorMsg += " | ${data['detail']}";
        } else {
          errorMsg += " | ${e.response?.data}";
        }
        debugPrint("Expert Submit Error: $errorMsg");
      } else {
        errorMsg += " | No response - Check internet";
        debugPrint("Expert Submit Network Error: $e");
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint("Unexpected error in submitExpertForReview: $e");
      throw Exception("Failed to submit application. Please try again.");
    }
  }

  // ──────────────────────────────────────────────────────────────
  // ENTREPRENEUR PROFILE FUNCTIONS
  // ──────────────────────────────────────────────────────────────
  Future<void> createEntrepreneurProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/v1/entrepreneurs/me/profile/',
        data: data,
      );
      debugPrint(
        "Entrepreneur profile saved successfully: ${response.statusCode}",
      );
    } on DioException catch (e) {
      String errorMsg = "Failed to save Startup profile";
      if (e.response != null) {
        errorMsg +=
            " | Status: ${e.response?.statusCode} | Data: ${e.response?.data}";
        debugPrint("Entrepreneur Profile Save Error: $errorMsg");
      } else {
        errorMsg += " | Connection failed";
        debugPrint("Entrepreneur Profile Network Error: $e");
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint("Unexpected error in createEntrepreneurProfile: $e");
      throw Exception("An unexpected error occurred");
    }
  }

  Future<void> submitEntrepreneurForReview({String note = ""}) async {
    try {
      final response = await _dio.post(
        '/api/v1/entrepreneurs/me/submit/',
        data: {"note": note},
      );
      debugPrint("Entrepreneur application submitted: ${response.statusCode}");
    } on DioException catch (e) {
      String errorMsg = "Failed to submit Startup application";
      if (e.response != null) {
        final data = e.response?.data;
        errorMsg += " | Status: ${e.response?.statusCode}";
        if (data is Map && data['detail'] != null) {
          errorMsg += " | ${data['detail']}";
        } else {
          errorMsg += " | ${e.response?.data}";
        }
        debugPrint("Entrepreneur Submit Error: $errorMsg");
      } else {
        errorMsg += " | No internet or server down";
        debugPrint("Entrepreneur Submit Failed: $e");
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint("Unexpected error in submitEntrepreneurForReview: $e");
      throw Exception("Submission failed. Please try again.");
    }
  }

  Future<Map<String, dynamic>?> getMyEntrepreneurProfile() async {
    try {
      final response = await _dio.get('/api/v1/entrepreneurs/me/profile/');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // return response.data as Map<String, dynamic>;
        _currentUser = User.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No profile exists yet → normal
        return null;
      }
      debugPrint("getMyEntrepreneurProfile Error: ${e.message}");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getExpertProfile() async {
    try {
      final response = await _dio.get('/api/v1/experts/me/profile/');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // return response.data as Map<String, dynamic>;
        _currentUser = User.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No profile exists yet → normal
        return null;
      }
      debugPrint("getMyEntrepreneurProfile Error: ${e.message}");
      rethrow;
    }
  }

  // Future<Map<String, dynamic>> getExpertProfile() async {
  //   try {
  //     final response = await _dio.get('/api/v1/experts/me/profile/');
  //    // return response.data;

  //   } on DioException catch (e) {
  //     debugPrint("getExpertProfile Error: $e");
  //     return {};
  //   }
  // }

  Future<List<dynamic>> getExpertExperiences() async {
    try {
      final response = await _dio.get('/api/v1/experts/experience/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      debugPrint("getExpertExperiences Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getExpertEducation() async {
    try {
      final response = await _dio.get('/api/v1/experts/education/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      debugPrint("getExpertEducation Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getExpertCertifications() async {
    try {
      final response = await _dio.get('/api/v1/experts/certifications/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      debugPrint("getExpertCertifications Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getExpertHonors() async {
    try {
      final response = await _dio.get('/api/v1/experts/honors/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      debugPrint("getExpertHonors Error: $e");
      return [];
    }
  }

  // ADD EXPERIENCE / EDUCATION / CERT / HONOR
  Future<void> addExperience(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/v1/experts/experience/', data: data);
    } on DioException catch (e) {
      debugPrint("addExperience error: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint("addExperience unexpected error: $e");
    }
  }

  Future<void> addEducation(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/v1/experts/education/', data: data);
    } on DioException catch (e) {
      debugPrint("addEducation error: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint("addEducation unexpected error: $e");
    }
  }

  Future<void> addCertification(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/v1/experts/certifications/', data: data);
    } on DioException catch (e) {
      debugPrint("addCertification error: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint("addCertification unexpected error: $e");
    }
  }

  Future<void> addHonor(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/v1/experts/honors/', data: data);
    } on DioException catch (e) {
      debugPrint("addHonor error: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint("addHonor unexpected error: $e");
    }
  }

  // ──────────────────────────────────────────────────────────────
  // GET COMPLETE EXPERT PROFILE (WITH ALL DATA)
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getMyExpertProfile() async {
    try {
      final response = await _dio.get('/api/v1/experts/me/profile/');
      print("Expert Profile Data: ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No profile exists yet → normal
        return null;
      }
      debugPrint("getMyExpertProfile Error: ${e.message}");
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // CREATE / UPDATE EXPERT PROFILE (BASIC INFO)
  // ──────────────────────────────────────────────────────────────
  Future<void> createOrUpdateExpertProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/v1/experts/me/profile/', data: data);
    } catch (e) {
      rethrow;
    }
  }
  // Add these inside your ApiProvider class

  Future<Map<String, dynamic>?> updateExpertBasicProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('/api/v1/experts/me/profile/', data: data);
      return response.data;
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateExperience(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/api/v1/experts/experience/$id/',
        data: data,
      );
      return response.data;
    } catch (e) {
      debugPrint("Update experience error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateEducation(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/api/v1/experts/education/$id/',
        data: data,
      );
      return response.data;
    } catch (e) {
      debugPrint("Update education error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateCertification(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/api/v1/experts/certifications/$id/',
        data: data,
      );
      return response.data;
    } catch (e) {
      debugPrint("Update certification error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateHonor(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('/experts/honors/$id/', data: data);
      return response.data;
    } catch (e) {
      debugPrint("Update honor error: $e");
      rethrow;
    }
  }

  Future<void> searchPosts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _dio.get(
        "/api/v1/community/search/",
        queryParameters: {"q": query.trim()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _searchResults = data
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Search error: $e");
      rethrow;
    }
  }

  // ────────────────────────────────────────
  // USER SEARCH (PEOPLE)
  // ────────────────────────────────────────

  List<User> _userSearchResults = [];
  List<User> get userSearchResults => _userSearchResults;

  void clearUserSearchResults() {
    _userSearchResults = [];
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _userSearchResults = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _dio.get(
        "/api/v1/auth/search/",
        queryParameters: {"q": query.trim()},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> results = data['results'] as List<dynamic>;

        _userSearchResults = results
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("User Search error: $e");
      rethrow;
    }
  }
}
