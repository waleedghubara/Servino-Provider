// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/core/theme/colors.dart';

import 'dart:async';
import 'package:servino_provider/features/chat/data/repo/chat_repo.dart';

class ConsultationWaitingDialog extends StatefulWidget {
  final VoidCallback onSupport;
  final int bookingId;
  final ChatRepository repository;

  const ConsultationWaitingDialog({
    super.key,
    required this.onSupport,
    required this.bookingId,
    required this.repository,
  });

  @override
  State<ConsultationWaitingDialog> createState() =>
      _ConsultationWaitingDialogState();
}

class _ConsultationWaitingDialogState extends State<ConsultationWaitingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final status = await widget.repository.getBookingStatus(
          widget.bookingId,
        );
        if (!mounted) return;

        final s = status?.trim().toLowerCase();
        if (s == 'completed' || s == 'done') {
          Navigator.of(context).pop(true); // Return true (Success)
        } else if (s == 'confirmed') {
          Navigator.of(context).pop(false); // Return false (Failure/Continue)
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass Effect Container
          ClipRRect(
            borderRadius: BorderRadius.circular(25.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.backgroundDark.withOpacity(0.2),
                            AppColors.backgroundDark.withOpacity(0.05),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary2.withOpacity(0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Title
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: Text(
                        'consultation_waiting_client'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primaryLight,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Dispute Message
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.03),
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        'consultation_dispute_info_msg'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.surface,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Support Button
                    InkWell(
                      onTap: widget.onSupport,
                      borderRadius: BorderRadius.circular(15.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.headset_mic_rounded,
                              size: 20.sp,
                              color: isDark ? Colors.white : AppColors.surface,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'chat_contact_support'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.surface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Cancel Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'cancel'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
