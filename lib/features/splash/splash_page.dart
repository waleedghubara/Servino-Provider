// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/core/config/app_config.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/theme/typography.dart';
import 'package:servino_provider/core/cache/cache_helper.dart';
import 'package:servino_provider/core/api/end_point.dart';
import 'package:servino_provider/core/ads/ads_manager.dart';

import '../../core/routes/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _logoScale = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _logoFade = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _titleFade = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    void executeNavigation() async {
      final token = await SecureCacheHelper().getData(key: ApiKey.token);
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(Routes.main);
      } else {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      }
    }

    // Checking if user is initialized and not subscribed
    // Or we simply show the ad. The AdsManager will fail gracefully if ads are disabled or not loaded.
    // However, the UserProvider might not be fully loaded with subscription status here.
    // The safest bet is to try to show it anyway; if they are a new login, they get an ad.
    // If we want to be strict about free plan, we might need to wait for UserProvider to load.
    // But Splash is before getting user data usually if token is present but not fetched.
    // Assuming AdsManager is initialized.
    AdsManager.instance.showAppOpenAd(
      onAdClosed: executeNavigation,
      onAdFailed: executeNavigation,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDotsLoader() {
    final double dotBase = 8.w;
    final double spacing = 10.w;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (value + i * 0.18) % 1.0;
            final pulse =
                0.55 + 0.45 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
            final opacity =
                (0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)))
                    .clamp(0.25, 1.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              width: dotBase * pulse,
              height: dotBase * pulse,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                const Spacer(),

                Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      Assets.logoApp,
                      width: 130.w,
                      height: 130.h,
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _titleFade,
                  child: Text(
                    'Servino Provider',
                    style: AppTypography.h2.copyWith(
                      fontSize: 28.sp,
                      fontFamily: 'XBFontEng2',
                      fontWeight: FontWeight.normal,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                _buildDotsLoader(),

                const Spacer(),

                Text(
                  AppConfig.appVersion,
                  style: AppTypography.h3.copyWith(
                    fontFamily: 'MAXIGO',
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
