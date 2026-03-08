import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String image;
  final List<ServiceItem> services;

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.image,
    required this.services,
  });

  String get name {
    if (navigatorKey.currentContext == null) return nameEn;
    return EasyLocalization.of(
              navigatorKey.currentContext!,
            )?.locale.languageCode ==
            'ar'
        ? nameAr
        : nameEn;
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      image: json['image'] ?? '',
      services: json['services'] != null
          ? (json['services'] as List)
                .map((e) => ServiceItem.fromJson(e))
                .toList()
          : [],
    );
  }
}

class ServiceItem {
  final String id;
  final String nameEn;
  final String nameAr;

  ServiceItem({required this.id, required this.nameEn, required this.nameAr});

  String get name {
    if (navigatorKey.currentContext == null) return nameEn;
    return EasyLocalization.of(
              navigatorKey.currentContext!,
            )?.locale.languageCode ==
            'ar'
        ? nameAr
        : nameEn;
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'].toString(),
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
    );
  }
}

// Global Key for accessing context without BuildContext (mock)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
