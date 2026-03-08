// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/features/notifications/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/features/notifications/providers/notification_provider.dart';

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsSheet({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              SizedBox(height: 12.h),
              Container(
                width: 60.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
              SizedBox(height: 20.h),

              // Title Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'notification_details'.tr(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[100],
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 30.h,
                  ),
                  child: Column(
                    children: [
                      // Icon Badge
                      Container(
                        width: 90.w,
                        height: 90.w,
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.primary.withOpacity(0.08),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(
                                isDark ? 0.3 : 0.2,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: SvgPicture.asset(_getIcon(notification.type)),
                      ),

                      SizedBox(height: 10.h),

                      // Title
                      Text(
                        notification.title.isEmpty
                            ? 'No Title'
                            : notification.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2D3436),
                          height: 1.3,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Time
                      Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Description Box
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252525)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.description.isEmpty
                                  ? 'No details provided.'
                                  : notification.description,
                              style: TextStyle(
                                fontSize: 16.sp,
                                height: 1.6,
                                color: isDark
                                    ? Colors.grey[300]
                                    : const Color(0xFF4A5568),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Action Button (if applicable)
                      if (notification.type == NotificationType.booking)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Add navigation logic here if needed
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 10,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text(
                                'view_booking_details'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Delete Button
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: OutlinedButton(
                          onPressed: () {
                            context
                                .read<NotificationProvider>()
                                .deleteNotification(
                                  context.read<UserProvider>().user!.id,
                                  notification.id,
                                );
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'delete_notification'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Assets.bookingchats;
      case NotificationType.wallet:
        return Assets.wallet;
      case NotificationType.system:
        return Assets.notifications;
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(time);
  }
}
