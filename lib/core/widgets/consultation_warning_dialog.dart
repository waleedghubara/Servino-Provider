// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/core/theme/colors.dart';

class ConsultationWarningDialog extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSupport;

  const ConsultationWarningDialog({
    super.key,
    required this.onBack,
    required this.onSupport,
  });

  @override
  State<ConsultationWarningDialog> createState() =>
      _ConsultationWarningDialogState();
}

class _ConsultationWarningDialogState extends State<ConsultationWarningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
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
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withOpacity(
                        0.1,
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
                        // Icon
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warning.withOpacity(0.2),
                                AppColors.warning.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 32.sp,
                            color: AppColors.warning,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Title
                        Text(
                          'consultation_warning_msg'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : AppColors.surface,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                context,
                                'ok'.tr(),
                                widget.onBack,
                                isPrimary: true,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Support Button
                        SizedBox(height: 12.h),
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
                                  : AppColors.primary.withOpacity(0.1),
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
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.primary,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    required bool isPrimary,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.8)
              : (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(0.2),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white : AppColors.surface),
            ),
          ),
        ),
      ),
    );
  }
}
