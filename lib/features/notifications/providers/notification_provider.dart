import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repo/notification_repo.dart';

import 'package:servino_provider/core/api/api_consumer.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepo _repo;

  NotificationProvider({required ApiConsumer api})
    : _repo = NotificationRepo(api: api);
  StreamSubscription<List<NotificationModel>>? _subscription;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void init(String userId) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repo.getUserNotifications(userId).listen((data) {
      _notifications = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }

    await _repo.markAsRead(userId, notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _repo.markAllAsRead(userId);
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    // Optimistic update
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    try {
      await _repo.deleteNotification(userId, notificationId);
    } catch (e) {
      // Revert if failed (optional, but good UX)
      // For now, we assume success or user will refresh
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
