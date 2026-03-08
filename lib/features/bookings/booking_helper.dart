// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:servino_provider/core/theme/colors.dart';

class BookingHelper {
  static String getLocalizedStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || status == 'قيد الانتظار') {
      return 'booking_status_pending'.tr();
    }
    if (s == 'confirmed' || status == 'مؤكد') {
      return 'booking_status_confirmed'.tr();
    }
    if (s == 'on the way' || status == 'في الطريق') {
      return 'booking_status_on_way'.tr();
    }
    if (s == 'arrived' || status == 'وصل' || status == 'وصلت') {
      return 'booking_status_arrived'.tr();
    }
    if (s == 'completed' || status == 'مكتمل' || s == 'finished') {
      return 'booking_status_completed'.tr();
    }
    if (s == 'rejected' ||
        status == 'مرفوض' ||
        s == 'declined' ||
        s == 'cancelled') {
      return 'booking_status_rejected'.tr();
    }
    if (s == 'completionrequested') {
      return 'booking_status_completion_requested'.tr();
    }
    return status;
  }

  static String getLocalizedType(String type) {
    final t = type.toLowerCase();
    if (t == 'consultation' || type == 'استشاره') {
      return 'bookings_tab_consultation'.tr();
    }
    if (t == 'coming to me' || type == 'موعد للقدوم اليا') {
      return 'bookings_tab_coming_to_me'.tr();
    }
    if (t == 'going to him' || type == 'موعد للقدوم اليه') {
      return 'bookings_tab_going_to_him'.tr();
    }
    return type;
  }

  static Color getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || status == 'قيد الانتظار') {
      return AppColors.warning.withOpacity(0.12);
    }
    if (s == 'completed' || status == 'مكتمل' || s == 'finished') {
      return AppColors.textSecondary.withOpacity(0.12);
    }
    if (s == 'rejected' ||
        status == 'مرفوض' ||
        s == 'declined' ||
        s == 'cancelled') {
      return AppColors.error.withOpacity(0.12);
    }
    if (s == 'confirmed' ||
        status == 'مؤكد' ||
        s == 'on the way' ||
        s == 'arrived' ||
        status == 'وصل' ||
        status == 'وصلت') {
      return AppColors.success.withOpacity(0.12);
    }
    return AppColors.textLight.withOpacity(0.12); // Default
  }

  static Color getStatusTextColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || status == 'قيد الانتظار') {
      return AppColors.warning;
    }
    if (s == 'completed' || status == 'مكتمل' || s == 'finished') {
      return AppColors.textSecondary;
    }
    if (s == 'rejected' ||
        status == 'مرفوض' ||
        s == 'declined' ||
        s == 'cancelled') {
      return AppColors.error;
    }
    if (s == 'confirmed' ||
        status == 'مؤكد' ||
        s == 'on the way' ||
        s == 'arrived' ||
        status == 'وصل' ||
        status == 'وصلت') {
      return AppColors.success;
    }
    return AppColors.textLight; // Default
  }
}
