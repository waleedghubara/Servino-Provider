import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { booking, wallet, system }

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(dynamic doc) {
    Map<String, dynamic> data;
    String id;

    if (doc is DocumentSnapshot) {
      data = doc.data() as Map<String, dynamic>;
      id = doc.id;
    } else {
      data = doc;
      id = doc['id'].toString();
    }

    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      description: data['body'] ?? data['description'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(
                  data['timestamp']?.toString() ??
                      data['created_at']?.toString() ??
                      '',
                ) ??
                DateTime.now(),
      type: _parseType(data['type']),
      isRead: (data['is_read'] is int)
          ? (data['is_read'] == 1)
          : (data['is_read'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': description,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      'is_read': isRead,
    };
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'booking':
        return NotificationType.booking;
      case 'wallet':
        return NotificationType.wallet;
      default:
        return NotificationType.system;
    }
  }
}
