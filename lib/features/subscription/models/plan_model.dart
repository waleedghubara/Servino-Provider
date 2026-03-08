import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';

class PlanModel {
  final int id;
  final String nameEn;
  final String nameAr;
  final String nameTr;
  final String featuresEn;
  final String featuresAr;
  final String featuresTr;
  final String priceMonthly;
  final String priceYearly;
  final String? discountTextEn;
  final String? discountTextAr;
  final String? discountTextTr;
  final int discountPercentage;
  final int durationDays;
  final Color color;
  final Color color2;
  final String? imagePath;
  final bool isPopular;
  final bool isBestValue;

  PlanModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.nameTr,
    required this.featuresEn,
    required this.featuresAr,
    required this.featuresTr,
    required this.priceMonthly,
    required this.priceYearly,
    this.discountTextEn,
    this.discountTextAr,
    this.discountTextTr,
    this.discountPercentage = 0,
    required this.durationDays,
    required this.color,
    required this.color2,
    this.imagePath,
    this.isPopular = false,
    this.isBestValue = false,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    // Assign generic colors/images based on ID or random for now if not in DB
    // Or we could have them in DB. For now, we cycle or pick based on ID.
    final id = int.tryParse(json['id'].toString()) ?? 0;

    // Default colors based on ID/Tier logic
    Color c1, c2;
    String? img;

    if (id == 1) {
      // Basic
      c1 = const Color.fromARGB(255, 6, 156, 231);
      c2 = const Color.fromARGB(255, 152, 208, 236);
      img = Assets.free;
    } else if (id == 2) {
      // Standard
      c1 = const Color.fromARGB(255, 241, 197, 0);
      c2 = const Color.fromARGB(255, 243, 221, 21);
      img = Assets.premiumjson;
    } else {
      // Premium/VIP
      c1 = AppColors.primary22;
      c2 = AppColors.primary222;
      img = Assets.vip;
    }

    // Helper to safely get nested or flat localized string
    String getLocalized(String key, String langCode, String flatKey) {
      if (json[key] is Map) {
        return json[key][langCode]?.toString() ?? '';
      }
      return json[flatKey]?.toString() ?? '';
    }

    int parsedDiscount =
        (double.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0.0)
            .toInt();

    // Fallback: If backend returns 0 for discount_percentage but text is present like "وفر 20%"
    if (parsedDiscount == 0) {
      final texts = [
        getLocalized('discount_text', 'en', 'discount_text_en'),
        getLocalized('discount_text', 'ar', 'discount_text_ar'),
        getLocalized('discount_text', 'tr', 'discount_text_tr'),
      ];
      final regex = RegExp(r'(\d+)');
      for (var t in texts) {
        if (t.isNotEmpty) {
          final match = regex.firstMatch(t);
          if (match != null) {
            parsedDiscount = int.tryParse(match.group(1) ?? '0') ?? 0;
            if (parsedDiscount > 0) break;
          }
        }
      }
    }

    return PlanModel(
      id: id,
      nameEn: getLocalized('name', 'en', 'name_en'),
      nameAr: getLocalized('name', 'ar', 'name_ar'),
      nameTr: getLocalized('name', 'tr', 'name_tr'),
      featuresEn: getLocalized('features', 'en', 'features_en'),
      featuresAr: getLocalized('features', 'ar', 'features_ar'),
      featuresTr: getLocalized('features', 'tr', 'features_tr'),
      priceMonthly:
          json['price_monthly']?.toString() ?? json['price']?.toString() ?? '0',
      priceYearly: json['price_yearly']?.toString() ?? '0',
      discountTextEn: getLocalized('discount_text', 'en', 'discount_text_en'),
      discountTextAr: getLocalized('discount_text', 'ar', 'discount_text_ar'),
      discountTextTr: getLocalized('discount_text', 'tr', 'discount_text_tr'),
      discountPercentage: parsedDiscount,
      durationDays: 30, // Default or unused for now
      color: c1,
      color2: c2,
      imagePath: img,
      isPopular: json['is_popular'] == true,
      isBestValue: json['is_best_value'] == true,
    );
  }

  // Localized Getters
  String getLocalizedTitle(BuildContext context) {
    final code = context.locale.languageCode;
    if (code == 'ar') return nameAr;
    if (code == 'tr') return nameTr;
    return nameEn;
  }

  String? getLocalizedDiscount(BuildContext context) {
    final code = context.locale.languageCode;
    if (code == 'ar') return discountTextAr;
    if (code == 'tr') return discountTextTr;
    return discountTextEn;
  }

  List<String> getLocalizedFeatures(BuildContext context) {
    final code = context.locale.languageCode;
    String raw = featuresEn;
    if (code == 'ar') raw = featuresAr;
    if (code == 'tr') raw = featuresTr;

    if (raw.isEmpty) return [];
    return raw.split('\n');
  }

  // Compat getters
  String get title => nameEn;
  String get price => priceMonthly;
}
