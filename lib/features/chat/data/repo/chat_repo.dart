// ignore_for_file: use_rethrow_when_possible

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/api_consumer.dart';
import 'package:servino_provider/core/api/end_point.dart'; // Added import
import 'package:servino_provider/core/model/message_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatRepository {
  final ApiConsumer api;

  ChatRepository({required this.api});

  Future<Box> _getMessagesBox(String otherUserId) async {
    final boxName = 'messages_$otherUserId';
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<List<MessageModel>> getLocalMessages(String userId) async {
    try {
      final box = await _getMessagesBox(userId);
      final data = box.get('messages', defaultValue: []);
      if (data != null && data is List) {
        return List<MessageModel>.from(
          data.map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<MessageModel>> getMessages(String userId) async {
    try {
      final response = await api.get(
        'chat/get_messages.php',
        queryParameters: {'user_id': userId},
      );

      if (response['status'] == 1 && response['data'] != null) {
        final messages = (response['data'] as List).map((e) {
          return MessageModel.fromJson(Map<String, dynamic>.from(e));
        }).toList();

        // Cache messages for this user
        final box = await _getMessagesBox(userId);
        // Convert to Map for storage
        final messagesJson = messages.map((m) => m.toJson()).toList();
        await box.put('messages', messagesJson);

        return messages;
      }
      return [];
    } catch (e) {
      throw e;
    }
  }

  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
    int? bookingId,
    String? replyToId,
    Map<String, dynamic>? replyToData,
  }) async {
    try {
      final response = await api.post(
        'chat/send.php',
        data: {
          'receiver_id': receiverId,
          'content': content,
          'type': type,
          if (bookingId != null) 'booking_id': bookingId,
          if (replyToId != null) 'reply_to_id': replyToId,
          if (replyToData != null) 'reply_to_data': replyToData,
        },
      );
      return response['status'] == 1;
    } catch (e) {
      return false;
    }
  }

  static const String _boxName = 'provider_conversations_box';

  Future<Box> _getConversationsBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<Map<String, dynamic>>> getLocalConversations() async {
    try {
      final box = await _getConversationsBox();
      final data = box.get('conversations', defaultValue: []);
      if (data != null && data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await api.get('chat/get_conversations.php');
      if (response['status'] == 1 && response['data'] != null) {
        final conversations = List<Map<String, dynamic>>.from(response['data']);

        // Cache the data
        final box = await _getConversationsBox();
        await box.put('conversations', conversations);

        return conversations;
      }
      return [];
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    try {
      await api.post(
        'bookings/update_status.php',
        data: {'booking_id': bookingId, 'status': status},
      );
    } catch (e) {
      throw e;
    }
  }

  Future<String?> getBookingStatus(int bookingId) async {
    try {
      final response = await api.get(
        'bookings/read_status.php',
        queryParameters: {'booking_id': bookingId},
      );
      // print("Booking Status Response: $response"); // Debug log
      if (response['status'] == 1 && response['data'] != null) {
        if (response['data'] is Map) {
          return response['data']['status']?.toString();
        } else if (response['data'] is String) {
          // In case API returns data: "completed" directly? Unlikely based on log but possible
          return response['data'];
        }
      }
      return null;
    } catch (e) {
      // print("Error getting booking status: $e");
      return null;
    }
  }

  Future<String> uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await api.post(
        'upload/file.php',
        data: formData, // Dio handles FormData
        isFromData: false,
      );

      if (response['status'] == 1) {
        return response['url'];
      }
      throw Exception('Upload failed');
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUserStatus(
    String userId,
    bool isOnline, {
    String? role,
  }) async {
    try {
      await api.post(
        EndPoint.updateStatus,
        data: {
          'user_id': userId,
          'is_online': isOnline,
          if (role != null) 'role': role,
        },
      );
    } catch (e) {
      // Fail silently
    }
  }

  Future<Map<String, dynamic>?> getUserStatus(
    String userId, {
    String? role,
  }) async {
    try {
      final response = await api.get(
        EndPoint.getUserStatus,
        queryParameters: {'user_id': userId, if (role != null) 'role': role},
      );
      if (response['status'] == 1 && response['data'] != null) {
        return response['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> markMessagesAsRead(
    String partnerId, {
    String role = 'client',
  }) async {
    try {
      await api.post(
        'chat/mark_read.php',
        data: {'partner_id': partnerId, 'role': role},
      );
    } catch (e) {
      // Fail silently
    }
  }
}
