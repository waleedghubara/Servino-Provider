import 'package:servino_provider/core/api/api_consumer.dart';
import 'package:servino_provider/core/api/end_point.dart';
import '../models/notification_model.dart';
import 'dart:async';

class NotificationRepo {
  final ApiConsumer api;

  NotificationRepo({required this.api});

  // Poll for notifications every 10 seconds to simulate a stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) async* {
    while (true) {
      try {
        final response = await api.post(
          EndPoint.getNotifications,
          data: {
            'user_id': userId,
            'user_type': 'provider', // Explicitly fetch provider notifications
          },
        );

        if (response['status'] == 1) {
          final List data = response['data'];
          yield data
              .map((json) => NotificationModel.fromFirestore(json))
              .toList();
        } else {
          yield [];
        }
      } catch (e) {
        // Yield empty list on error to prevent infinite loading
        yield [];
      }
      await Future.delayed(const Duration(seconds: 10)); // Poll interval
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await api.post(
        EndPoint.markRead,
        data: {'user_id': userId, 'notification_id': notificationId},
      );
    } catch (e) {
      // Handle error cleanly
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await api.post(
        EndPoint.markRead,
        data: {'user_id': userId, 'mark_all': true},
      );
    } catch (e) {
      // Handle error cleanly
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await api.post(
        'notifications/delete_notification.php',
        data: {'user_id': userId, 'notification_id': notificationId},
      );
    } catch (e) {
      // Handle error cleanly
    }
  }
}

// Helper to adapt JSON to existing "fromFirestore" if we don't want to change the model yet.
class MockDoc {
  final Map<String, dynamic> _data;
  MockDoc(this._data);
  Map<String, dynamic> data() => _data;
  String get id => _data['id'].toString();
}
