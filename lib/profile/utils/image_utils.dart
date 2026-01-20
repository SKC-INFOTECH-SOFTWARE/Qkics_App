import 'package:q_kics/providers/api_provider.dart';

String? resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;

  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  final String baseUrl = ApiProvider().dio.options.baseUrl;

  // avoid double slashes
  if (baseUrl.endsWith('/') && path.startsWith('/')) {
    return baseUrl.substring(0, baseUrl.length - 1) + path;
  }

  if (!baseUrl.endsWith('/') && !path.startsWith('/')) {
    return '$baseUrl/$path';
  }

  return '$baseUrl$path';
}
