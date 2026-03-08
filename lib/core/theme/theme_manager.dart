import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  /// Initialize theme from Hive
  Future<void> initTheme() async {
    final box = Hive.box('settings');
    final isDark = box.get('isDarkMode');

    if (isDark != null) {
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;

    // Save to Hive
    final box = Hive.box('settings');
    if (mode == ThemeMode.dark) {
      box.put('isDarkMode', true);
    } else if (mode == ThemeMode.light) {
      box.put('isDarkMode', false);
    } else {
      box.delete('isDarkMode');
    }
  }
}
