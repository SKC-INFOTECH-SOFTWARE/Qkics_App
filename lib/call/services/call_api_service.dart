import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:q_kics/call/models/call_models.dart';
import 'package:q_kics/providers/api_provider.dart';

class CallApiService {
  final Dio _dio;

  CallApiService({Dio? dio}) : _dio = dio ?? ApiProvider().dio;

  /// GET /api/v1/calls/{room_id}/
  /// Returns room detail + livekit_token + livekit_url
  Future<CallRoom> getRoom(String roomId) async {
    final response = await _dio.get('/api/v1/calls/$roomId/');
    return CallRoom.fromJson(response.data);
  }

  /// POST /api/v1/calls/
  /// Creates a call room for a confirmed booking.
  Future<CallRoom> createRoomForBooking(String bookingId) async {
    final response = await _dio.post(
      '/api/v1/calls/',
      data: {'booking_id': bookingId},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['room'] is Map<String, dynamic>) {
      return CallRoom.fromJson(data['room']);
    }

    return CallRoom.fromJson(data);
  }

  /// POST /api/v1/calls/{room_id}/end/
  Future<void> endCall(String roomId) async {
    await _dio.post('/api/v1/calls/$roomId/end/');
  }

  /// GET /api/v1/calls/{room_id}/messages/
  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    final response = await _dio.get('/api/v1/calls/$roomId/messages/');
    final List list = response.data as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/calls/my/
  Future<List<CallRoom>> getMyRooms() async {
    final response = await _dio.get('/api/v1/calls/my/');
    final List list = response.data as List;
    return list.map((j) => CallRoom.fromJson(j)).toList();
  }

  /// POST /api/v1/calls/{room_id}/upload/
  /// Uploads a file to the call room chat. Returns the created message data.
  Future<Map<String, dynamic>> uploadFile(
    String roomId,
    String fileName,
    List<int> fileBytes,
  ) async {
    final contentType = _contentTypeFor(fileName);
    debugPrint('[CallApi] uploading "$fileName" (${fileBytes.length} bytes, $contentType) to room $roomId');
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    // Do NOT set Content-Type manually — Dio auto-sets it with the correct boundary.
    final response = await _dio.post(
      '/api/v1/calls/$roomId/upload/',
      data: formData,
    );
    debugPrint('[CallApi] upload response: ${response.statusCode} ${response.data}');
    return response.data as Map<String, dynamic>;
  }

  static String _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
      'txt': 'text/plain',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  /// GET /api/v1/calls/{room_id}/notes/
  Future<List<Map<String, dynamic>>> getNotes(String roomId) async {
    final response = await _dio.get('/api/v1/calls/$roomId/notes/');
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// POST /api/v1/calls/{room_id}/notes/
  Future<Map<String, dynamic>> createNote(String roomId, String content) async {
    final response = await _dio.post(
      '/api/v1/calls/$roomId/notes/',
      data: {'content': content},
    );
    return response.data as Map<String, dynamic>;
  }
}
