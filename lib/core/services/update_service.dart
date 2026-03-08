import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  // Singleton pattern to ensure only one instance of UpdateService exists
  UpdateService._privateConstructor();
  static final UpdateService _instance = UpdateService._privateConstructor();
  factory UpdateService() => _instance;

  Future<void> checkForUpdate() async {
    // 1. Ensure the code only runs on Android (not Web, iOS, etc.)
    if (kIsWeb || !Platform.isAndroid) {
      // debugPrint('In-App Update is only supported on Android devices.');
      return;
    }

    try {
      // 2. Check for update availability
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      // 3. If an update is available and an immediate update is allowed
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed) {
        // debugPrint('Update available! Triggering immediate update...');

        // Trigger immediate update using Google Play's native UI
        await InAppUpdate.performImmediateUpdate();
      } else {
        // debugPrint('No immediate update available.');
      }
    } catch (e) {
      // 4. Complete error handling with try-catch so the app doesn't crash
      // if the device doesn't support In-App Update or other errors occur.
      // debugPrint('Failed to check for in-app update: $e');
    }
  }
}
