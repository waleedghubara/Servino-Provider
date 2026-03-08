// ignore_for_file: deprecated_member_use

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_provider/core/theme/colors.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/assets.dart';

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the isApproved flag from arguments, default to false
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isApproved = args?['isApproved'] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [AppColors.primary2, AppColors.backgroundDark]
                      : [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.background,
                        ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Animation
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Lottie.asset(
                      isApproved ? Assets.success : Assets.wait,
                      height: 300.h,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Title & Description
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        Text(
                          isApproved
                              ? 'register_approved_title'.tr()
                              : 'register_success_title'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          isApproved
                              ? 'register_approved_desc'.tr()
                              : 'register_success_desc'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 1000),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (isApproved) {
                            AppRouter.navigateAndRemoveUntil(
                              context,
                              Routes.main,
                            );
                          } else {
                            // Go back to login or just pop
                            AppRouter.navigateAndRemoveUntil(
                              context,
                              Routes.login,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 5,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              isApproved
                                  ? 'get_started'.tr()
                                  : 'back_to_login'.tr(),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
