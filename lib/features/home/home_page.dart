// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'dart:math' as math;
import 'package:servino_provider/core/theme/colors.dart';
import 'dart:ui' as ui;
import 'package:servino_provider/features/payment/models/payment_params.dart';
import 'package:servino_provider/features/auth/data/models/user_model.dart';

import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/features/auth/data/repo/auth_repo.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/features/subscription/data/repo/subscription_repo.dart';
import 'package:servino_provider/features/subscription/subscription_page.dart';
import 'package:servino_provider/features/payment/data/repo/payment_repo.dart';
import 'package:servino_provider/features/payment/models/financial_reports_model.dart';
import 'package:servino_provider/features/home/widgets/financial_dashboard.dart';
// import 'package:servino_provider/features/home/financial_reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FinancialReportModel? _financialReports;
  bool _isLoadingReports = true;

  @override
  void initState() {
    super.initState();
    // Refresh user data on home page entry to ensure subscription days are accurate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
      _fetchFinancialReports();
    });
  }

  Future<void> _fetchFinancialReports() async {
    try {
      final repo = PaymentRepository(api: DioConsumer(dio: Dio()));
      final reports = await repo.getFinancialReports();
      if (mounted) {
        setState(() {
          _financialReports = reports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
      // debugPrint('Error fetching financial reports: $e');
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authRepo = AuthRepository(api: DioConsumer(dio: Dio()));
      await userProvider.refreshUser(authRepo);
    } catch (e) {
      // debugPrint('Error refreshing user data on home: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                final authRepo = AuthRepository(api: DioConsumer(dio: Dio()));
                await userProvider.refreshUser(authRepo);
              },
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isDark, user),
                    SizedBox(height: 30.h),
                    if (userProvider.isSubscribed)
                      _buildSubscriptionSection(context, isDark, userProvider)
                    else
                      _buildSubscribeCTA(context, isDark),
                    SizedBox(height: 10.h),
                    if (_isLoadingReports)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (_financialReports != null)
                        FinancialDashboard(
                          reports: _financialReports!,
                          isDark: isDark,
                        ),
                      SizedBox(height: 20.h),
                      _buildStatsSection(context, isDark, user),
                    ],
                    SizedBox(height: 70.h), // Spacing for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, UserModel? user) {
    // Plan & Frame Logic
    final bool isSubscribed = user?.isSubscribed ?? false;
    final int planId = user?.currentPlanId ?? 0;

    String? frameAsset;
    if (planId == 3) {
      frameAsset = Assets.goldFrame;
    } else if (planId == 2) {
      frameAsset = Assets.diamondFrame;
    }

    // Avatar Provider Logic
    ImageProvider imageProvider;
    if (user?.fullProfileImageUrl != null &&
        user!.fullProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(user.fullProfileImageUrl!);
    } else {
      imageProvider = const AssetImage(Assets.userAvatar);
    }

    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isSubscribed && frameAsset != null)
                              ? Colors.transparent
                              : AppColors.primary,
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (frameAsset != null)
                      Positioned(
                        top: -10.h,
                        bottom: -10.h,
                        left: -10.w,
                        right: -10.w,
                        child: Image.asset(frameAsset, fit: BoxFit.contain),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home_welcome'.tr(), // "Welcome,"
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        user?.name ?? 'Guest', // Dynamic name
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Row(
            children: [
              // Notification Icon
              Stack(
                children: [
                  FadeInRight(
                    duration: const Duration(milliseconds: 800),
                    child: GestureDetector(
                      onTap: () =>
                          AppRouter.navigateTo(context, Routes.notifications),
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey[200]!,
                          ),
                        ),
                        child: SvgPicture.asset(
                          Assets.notifications,
                          width: 26.sp,
                          height: 26.sp,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.r,
                    right: 12.r,
                    child: Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 5.w),

              if (user != null)
                GestureDetector(
                  onTap: () => AppRouter.navigateTo(context, Routes.wallet),
                  child: Container(
                    height: 40.h,
                    width: 90.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.3),

                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "${user.balance?.toStringAsFixed(2) ?? '0.00'} ${'currency_egy'.tr()}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: 'XBFont_ENG',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SvgPicture.asset(
                          Assets.wallet,

                          width: 26.sp,
                          height: 26.sp,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(
    BuildContext context,
    bool isDark,
    UserProvider userProvider,
  ) {
    // Dynamic Data
    final user = userProvider.user;
    String currentPlan = 'plan_free';
    if (userProvider.isSubscribed) {
      switch (user?.currentPlanId) {
        case 3:
          currentPlan = 'plan_vip';
          break;
        case 2:
          currentPlan = 'plan_pro';
          break;
        default:
          currentPlan = 'plan_pro';
      }
    }
    bool isVip = userProvider.isSubscribed;
    // Use Backend Values directly
    int totalDays = user?.totalDays ?? 30;
    int daysLeft = user?.daysRemaining ?? 0;

    // Safety check just in case
    if (totalDays <= 0) totalDays = 30;

    // State-Level Colors: Deep, authoritative gradients
    List<Color> cardGradient = isDark
        ? [AppColors.surfaceDark, const Color(0xFF2C3E50)]
        : [AppColors.primary2, AppColors.primary]; // White -> Slate 100

    Color accentColor = isVip
        ? const Color(0xFFF59E0B) // Amber 500
        : const Color(0xFF3B82F6); // Blue 500

    if (daysLeft <= 0) {
      accentColor = const Color.fromARGB(255, 255, 0, 0); // Red 500
    }

    // Determine Standard Denominator for Gauge
    // If totalDays > 40, assume Yearly (365). Else Monthly (30).
    final int standardTotal = totalDays > 40 ? 365 : 30;

    return FadeInUp(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 30, // Softer shadow
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 10.r,
                bottom: 24.r,
                left: 16.r,
                right: 16.r,
              ),
              child: Column(
                children: [
                  // Plan Name & Status
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(color: accentColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 30, // Softer shadow
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentPlan.tr().toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (daysLeft <= 0) ...[
                          SizedBox(width: 8.w),
                          Text(
                            "| EXPIRED",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 255, 25, 0),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // The Gauge
                      SizedBox(
                        width: 140.w,
                        height: 140.w,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: daysLeft.toDouble()),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            // Calculate percentage based on Standard Total (365 or 30)
                            double p = (standardTotal > 0)
                                ? (value / standardTotal).clamp(0.0, 1.0)
                                : 0.0;
                            return CustomPaint(
                              painter: _StateLevelGaugePainter(
                                percent: p,
                                gradientColors: [
                                  accentColor.withOpacity(0.4),
                                  accentColor,
                                ],
                                isDark: isDark,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    daysLeft <= 0 ? "0" : "${value.toInt()}",
                                    style: TextStyle(
                                      fontSize: 36.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    "days_left".tr(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Action Bar (Unified)
                  // Action Bar (Unified)
                  Row(
                    children: [
                      // Renew Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: daysLeft <= 0
                              ? () async {
                                  // Show Loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );

                                  try {
                                    // Fetch Plans to get original price
                                    final repo = SubscriptionRepository(
                                      api: DioConsumer(dio: Dio()),
                                    );
                                    final plans = await repo.getPlans();
                                    final int planId = user?.currentPlanId ?? 0;

                                    Navigator.pop(context); // Close loader

                                    // If planId is invalid, force user to choose
                                    if (planId == 0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SubscriptionPage(
                                                currentPlanTitle: currentPlan,
                                              ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Find current plan
                                    final plan = plans.firstWhere(
                                      (p) => p.id == planId,
                                      orElse: () => plans.first,
                                    );

                                    // Determine Billing Cycle (Approximation based on last subscription duration)
                                    // If > 200 days, assume Yearly. Else Monthly.
                                    // This preserves the "Original Price" logic user asked for.
                                    final bool isYearly =
                                        (user?.totalDays ?? 30) > 200;

                                    String priceStr = isYearly
                                        ? plan.priceYearly
                                        : plan.priceMonthly;
                                    double amount =
                                        double.tryParse(priceStr) ?? 0.0;

                                    // Apply discount if exists
                                    if (plan.discountPercentage > 0) {
                                      amount =
                                          amount *
                                          (1 - plan.discountPercentage / 100);
                                      amount = double.parse(
                                        amount.toStringAsFixed(2),
                                      );
                                    }

                                    final params = PaymentParams(
                                      title: plan.title,
                                      amount: amount,
                                      currency:
                                          '\$', // Or dynamically if available
                                      description: isYearly
                                          ? 'billing_yearly'
                                          : 'billing_monthly',
                                      isSubscription: true,
                                      planId: plan.id.toString(),
                                      originalAmount:
                                          double.tryParse(priceStr) ?? 0.0,
                                      discountPercentage:
                                          plan.discountPercentage,
                                    );

                                    AppRouter.navigateTo(
                                      context,
                                      Routes.paymentMethodSelection,
                                      arguments: params,
                                    );
                                  } catch (e) {
                                    Navigator.pop(context); // Close loader
                                    // On error, fallback to subscription page
                                    AppRouter.navigateTo(
                                      context,
                                      Routes.subscription,
                                      // If arguments supported by router for this route, use them.
                                      // But since we are replacing with direct push in other places,
                                      // let's stick to MaterialPageRoute for consistency or check if AppRouter supports args.
                                      // To be safe and consistent with ProfilePage:
                                    );
                                    // Actually, replacing with direct push:
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubscriptionPage(
                                          currentPlanTitle: currentPlan,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null, // Disabled unless expired
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: isDark
                                ? Colors.grey[600]
                                : Colors.grey[500],
                            elevation: daysLeft <= 0 ? 8 : 0,
                            shadowColor: accentColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text(
                            'renew_subscription'.tr(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Change Plan Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionPage(
                                currentPlanTitle: currentPlan,
                              ),
                            ),
                          ),

                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),

                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.w,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondaryLight,
                                  AppColors.primary,
                                  AppColors.error,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'choose_new_plan'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.white,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    bool isDark,
    UserModel? user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            "account_activity".tr(), // "Account Activity"
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Tajawal',
            ),
          ),
        ),

        _buildUnifiedStatsCard(context, isDark, user),
      ],
    );
  }

  Widget _buildUnifiedStatsCard(
    BuildContext context,
    bool isDark,
    UserModel? user,
  ) {
    // Data
    final requests = user?.totalRequests ?? 0;
    final completion = user?.profileCompletion ?? 0;
    final reports = user?.reportsCount ?? 0;

    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Gradient Background for "Professional" look
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.surfaceDark, const Color(0xFF2C3E50)]
                : [AppColors.primary2, AppColors.primary], // White -> Slate 100
          ),
          borderRadius: BorderRadius.circular(15.r), // Soft rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 30, // Softer shadow
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Top Section: Chart
            Container(
              height: 220.h,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 20.h),
              child: CustomPaint(
                painter: _PieChartPainter(
                  values: [
                    requests.toDouble(),
                    completion.toDouble(),
                    reports.toDouble(),
                  ], // Requests, Completion, Reports
                  colors: [
                    AppColors.success,
                    AppColors.secondaryLight,
                    AppColors.error,
                  ],
                  isDark: isDark,
                ),
              ),
            ),

            // Bottom Section: Metrics
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14.r),
                  bottomRight: Radius.circular(14.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfessionalMetric(
                    context,
                    "total_requests".tr(),
                    "${user?.totalRequests ?? 0}",
                    AppColors.success,
                    isDark,
                  ),
                  _buildDivider(isDark),
                  _buildProfessionalMetric(
                    context,
                    "profile_views".tr(),
                    "${user?.profileViews ?? 0}", // Corrected
                    AppColors.secondaryLight,
                    isDark,
                  ),
                  _buildDivider(isDark),
                  _buildProfessionalMetric(
                    context,
                    "total_reports".tr(),
                    "${user?.reportsCount ?? 0}",
                    AppColors.error,
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 60.h,
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey,
    );
  }

  Widget _buildProfessionalMetric(
    BuildContext context,
    String title,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeCTA(BuildContext context, bool isDark) {
    List<Color> cardGradient = isDark
        ? [AppColors.surfaceDark, const Color(0xFF2C3E50)]
        : [AppColors.primary2, AppColors.primary];

    return FadeInUp(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  Assets.premium,

                  width: 30.sp,
                  height: 30.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'unlock_premium'.tr(), // "Unlock Premium"
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'get_access_to_all_features'
                          .tr(), // "Get access to all features"
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SubscriptionPage(currentPlanTitle: 'plan_free'),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                ),
                child: Text(
                  'subscribe'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final bool isDark;

  _PieChartPainter({
    required this.values,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 25.0;

    double total = values.fold(0, (sum, item) => sum + item);
    if (total == 0) total = 1;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * math.pi;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt; // Clean butt ends

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Subtle Separate Glow
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.butt
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw text in the middle
    final textPainter = TextPainter(
      text: TextSpan(
        text: "stats_activity".tr(),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _StateLevelGaugePainter extends CustomPainter {
  final double percent;
  final List<Color> gradientColors;
  final bool isDark;

  _StateLevelGaugePainter({
    required this.percent,
    required this.gradientColors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 6.0; // Much thinner, elegant line

    // 1. Background Track (Subtle, dark/light ring)
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap
          .butt // Clean technical end
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // 2. Ticks (Optional "Dashboard" look)
    _drawTicks(canvas, center, radius, isDark);

    // 3. Progress Arc
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Gradient gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      tileMode: TileMode.repeated,
      colors: gradientColors,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percent;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // 4. Glow Tip (The "Jewel")
    if (percent > 0) {
      final tipAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final glowPaint = Paint()
        ..color = gradientColors.last.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(tipX, tipY), 8, glowPaint);

      final dotPaint = Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(tipX, tipY), 3, dotPaint);
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double radius, bool isDark) {
    final tickPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.3)
          : Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    final int tickCount = 40;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi) / tickCount;
      // Skip ticks covered by progress if you want cleanliness, or keep them for background
      final start = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StateLevelGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.gradientColors != gradientColors;
  }
}
