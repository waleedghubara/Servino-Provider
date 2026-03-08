import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/theme/typography.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';

class ServerErrorPage extends StatelessWidget {
  const ServerErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                children: [
                  FadeInDown(child: Lottie.asset(Assets.serverError)),
                  SizedBox(height: 100.h),
                  FadeInUp(
                    child: Text(
                      'server_error_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTypography.h2.copyWith(
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'server_error_desc'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Spacer(),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate back to the Splash Screen to reset the app flow
                        navigatorKey.currentState?.pushNamedAndRemoveUntil(
                          Routes.splash,
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'retry_btn'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
