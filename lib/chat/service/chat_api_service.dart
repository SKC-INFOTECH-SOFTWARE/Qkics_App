import 'package:dio/dio.dart';
import 'package:q_kics/chat/models/chat_message.dart';
import 'package:q_kics/chat/models/chat_room.dart';
import 'package:q_kics/providers/api_provider.dart';

class ChatApiService {
  final Dio _dio;

  ChatApiService({Dio? dio}) : _dio = dio ?? ApiProvider().dio;

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await _dio.get('/api/v1/chat/rooms/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatRoom.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching chat rooms: ${e.message}");
      rethrow;
    }
  }

  Future<List<ChatMessage>> getChatMessages(int roomId) async {
    try {
      final response = await _dio.get('/api/v1/chat/rooms/$roomId/messages/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        
        return data.map((json) => ChatMessage.fromJson(json)).toList();
        
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching chat messages: ${e.message}");
      rethrow;
    }
  }

  Future<ChatMessage?> sendMessage(
    int roomId,
    String text, {
    String? filePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({'text': text});

      if (filePath != null) {
        formData.files.add(
          MapEntry('file', await MultipartFile.fromFile(filePath)),
        );
      }

      final response = await _dio.post(
        '/api/v1/chat/rooms/$roomId/messages/',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ChatMessage.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Error sending message: ${e.message}");
      rethrow;
    }
  }
}
