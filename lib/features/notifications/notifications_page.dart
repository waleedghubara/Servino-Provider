// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/notifications/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/features/notifications/providers/notification_provider.dart';
import 'package:servino_provider/features/notifications/widgets/notification_details_sheet.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().init(user.id);
      }
    });
  }

  void _markAllAsRead() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      context.read<NotificationProvider>().markAllAsRead(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('all_notifications_marked_read'.tr()),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(child: AnimatedBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'notifications'.tr(),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: _markAllAsRead,
                icon: Icon(
                  Icons.done_all,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                tooltip: 'mark_all_read'.tr(),
              ),
            ],
          ),
          body: Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        Assets.notifications,
                        width: 100.w,
                        height: 100.h,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "notifications_no_notifications".tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return AnimatedList(
                key: _listKey,
                initialItemCount: provider.notifications.length,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                itemBuilder: (context, index, animation) {
                  // Ensure index is valid as list might change
                  if (index >= provider.notifications.length) return SizedBox();

                  return _buildNotificationItem(
                    context,
                    provider.notifications[index],
                    animation,
                    isDark,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    Animation<double> animation,
    bool isDark,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: animation,
        child: Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.w),
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.delete_outline, color: Colors.white, size: 30.sp),
          ),
          onDismissed: (direction) {
            final user = context.read<UserProvider>().user;
            if (user != null) {
              context.read<NotificationProvider>().deleteNotification(
                user.id,
                notification.id,
              );
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: notification.isRead
                    ? Colors.grey.shade300
                    : AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () {
                  final user = context.read<UserProvider>().user;
                  if (!notification.isRead && user != null) {
                    context.read<NotificationProvider>().markAsRead(
                      user.id,
                      notification.id,
                    );
                  }
                  _showNotificationDetails(context, notification);
                },
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildIcon(notification.type),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title.isEmpty
                                        ? 'No Title'
                                        : notification.title,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8.r,
                                    height: 8.r,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              notification.description.isEmpty
                                  ? 'No Description'
                                  : notification.description,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              _formatTime(notification.timestamp),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return NotificationDetailsSheet(notification: notification);
      },
    );
  }

  Widget _buildIcon(NotificationType type) {
    String iconData;

    switch (type) {
      case NotificationType.booking:
        iconData = Assets.bookingchats;
        break;
      case NotificationType.wallet:
        iconData = Assets.wallet;
        break;
      case NotificationType.system:
        iconData = Assets.notifications;
        break;
    }

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: SvgPicture.asset(iconData, width: 24.w, height: 24.h),
    );
  }

  String _formatTime(DateTime time) {
    // Simple time formatting logic
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${'mins_ago'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${'hours_ago'.tr()}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(time);
    }
  }
}
