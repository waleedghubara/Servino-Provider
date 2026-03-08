import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/auth/data/models/user_model.dart';
import '../cache/cache_helper.dart';
import '../services/firebase_messaging_service.dart';
import '../services/call/zego_service.dart';

import 'package:servino_provider/core/api/end_point.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final SecureCacheHelper _cacheHelper = SecureCacheHelper();
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final ZegoService _zegoService = ZegoService();
  static const String _userKey = 'user_data';

  UserModel? get user => _user;

  bool get isSubscribed => _user?.isSubscribed ?? false;
  int get daysRemaining => _user?.daysRemaining ?? 0;

  Future<void> loadUser() async {
    final userJson = await _cacheHelper.getDataString(key: _userKey);
    if (userJson != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson));
        // Refresh Token on Auto Login
        if (_user != null) {
          _messagingService.saveTokenToFirestore(_user!.id);
          await _zegoService.onUserLogin(
            _user!.id.toString(),
            _user!.name,
            _user!.profileImage,
          );
        }
        notifyListeners();
      } catch (e) {
        // Handle decode error
      }
    }
  }

  Future<void> saveUser(UserModel user) async {
    _user = user;
    await _cacheHelper.saveData(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
    // Save Token on Login/Register
    _messagingService.saveTokenToFirestore(user.id);
    await _zegoService.onUserLogin(
      user.id.toString(),
      user.name,
      user.profileImage,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _zegoService.onUserLogout();
    _user = null;
    await _cacheHelper.removeData(key: _userKey);
    await _cacheHelper.removeData(key: ApiKey.token);
    notifyListeners();
  }

  Future<void> refreshUser(dynamic authRepo) async {
    try {
      final userData = await authRepo.getProfile();
      if (userData != null) {
        final newUser = UserModel.fromJson(userData);
        await saveUser(newUser);
      }
    } catch (e) {
      // debugPrint('Error refreshing user: $e');
      rethrow;
    }
  }
}
