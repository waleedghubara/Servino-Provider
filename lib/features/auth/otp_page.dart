// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:alert_info/alert_info.dart';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/features/auth/data/repo/auth_repo.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/assets.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ... (rest of the file)

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isRegister = arguments?['isRegister'] ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  // Animation
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Lottie.asset(Assets.enterPassword, height: 200.h),
                  ),

                  SizedBox(height: 32.h),

                  // Title & Description
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        Text(
                          'otp_title'.tr(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'otp_desc'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 48.h),

                  // OTP Fields
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => SizedBox(
                                width: 45.w,
                                height: 60.h,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  onChanged: (value) =>
                                      _onOtpChanged(value, index),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.backgroundDark
                                        : const Color(0xFFF5F6FA),
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: AppColors.secondaryDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                String otp = _controllers
                                    .map((c) => c.text)
                                    .join();
                                if (otp.length != 6) {
                                  AlertInfo.show(
                                    context: context,
                                    text: 'Please enter valid 6-digit code',
                                  );
                                  return;
                                }

                                final email = arguments?['email'];
                                if (email == null) {
                                  AlertInfo.show(
                                    context: context,
                                    text: 'Email not found',
                                  );
                                  return;
                                }

                                try {
                                  // Only verify with backend if this is Registration flow
                                  // For Forgot Password, we verify the OTP in the next step (ResetPasswordPage)
                                  // because verify_otp.php clears the code, and we need it for the reset endpoint.
                                  if (isRegister) {
                                    final repo = AuthRepository(
                                      api: DioConsumer(dio: Dio()),
                                    );
                                    await repo.verifyOtp(
                                      email: email,
                                      otpCode: otp,
                                    );

                                    if (mounted) {
                                      AppRouter.navigateAndRemoveUntil(
                                        context,
                                        Routes.registerSuccess,
                                      );
                                    }
                                  } else {
                                    // Forgot Password Flow
                                    // Navigate directly. Verification happens in resetPassword API call.
                                    if (mounted) {
                                      AppRouter.navigateTo(
                                        context,
                                        Routes.resetPassword,
                                        arguments: {'email': email, 'otp': otp},
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AlertInfo.show(
                                      context: context,
                                      text: e.toString(),
                                    );
                                  }
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
                                    'otp_verify'.tr(),
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
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Resend Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 1000),
                    child: TextButton(
                      onPressed: _canResend
                          ? () async {
                              final email = arguments?['email'];
                              if (email == null) {
                                if (mounted) {
                                  AlertInfo.show(
                                    context: context,
                                    text: 'Email not found',
                                  );
                                }
                                return;
                              }

                              try {
                                final repo = AuthRepository(
                                  api: DioConsumer(dio: Dio()),
                                );
                                await repo.resendOtp(email: email);
                                startTimer();
                                if (mounted) {
                                  AlertInfo.show(
                                    context: context,
                                    text: 'OTP Resent Successfully',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  AlertInfo.show(
                                    context: context,
                                    text: e.toString(),
                                  );
                                }
                              }
                            }
                          : null,
                      child: Text(
                        _canResend
                            ? 'otp_resend'.tr()
                            : '${'otp_resend'.tr()} (${_start}s)',
                        style: TextStyle(
                          color: _canResend
                              ? (isDark ? Colors.white70 : AppColors.primary)
                              : Colors.grey,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
