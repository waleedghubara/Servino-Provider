import 'package:flutter/material.dart';

class LocalizationManager {
  LocalizationManager._();

  static const String translationsPath = 'assets/lang';
  static const Locale fallbackLocale = Locale('ar');

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
    Locale('zh'),
    Locale('ja'),
    Locale('ru'),
    Locale('pt'),
    Locale('hi'),
    Locale('tr'),
  ];
}
