// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';

import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/subscription/models/plan_model.dart';
import 'package:servino_provider/features/payment/models/payment_params.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/subscription/data/repo/subscription_repo.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';

class SubscriptionPage extends StatefulWidget {
  final String? currentPlanTitle;
  const SubscriptionPage({super.key, this.currentPlanTitle});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  int _billingCycle = 0; // 0 = Monthly, 1 = Yearly
  String _selectedPlanTitle = '';

  late SubscriptionRepository _repo;
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _selectedPlanTitle = widget.currentPlanTitle ?? '';
    _repo = SubscriptionRepository(api: DioConsumer(dio: Dio()));
    _loadPlans();
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

  Future<void> _loadPlans() async {
    try {
      final plans = await _repo.getPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
        if (_plans.isNotEmpty && _selectedPlanTitle.isEmpty) {
          _selectedPlanTitle = _plans[0].title;
        }
      });

      // Auto scroll to current plan if exists
      if (_selectedPlanTitle.isNotEmpty) {
        int initialIndex = _plans.indexWhere(
          (p) =>
              p.nameEn == _selectedPlanTitle || p.nameAr == _selectedPlanTitle,
        ); // rudimentary check
        if (initialIndex != -1) {
          _currentPage = initialIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(initialIndex);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPlanSelected(PlanModel plan) {
    if (plan.title == _selectedPlanTitle) return;

    // Check if user is already subscribed
    // Check if user is already subscribed AND has days remaining
    final userProvider = context.read<UserProvider>();
    final isExpired = (userProvider.user?.daysRemaining ?? 0) <= 0;

    // Only block if subscribed AND NOT expired
    if (userProvider.isSubscribed && !isExpired) {
      _showAlreadySubscribedDialog();
      return;
    }

    bool isFree =
        plan.priceMonthly == 'Free' ||
        (double.tryParse(plan.priceMonthly) == 0);

    if (isFree) {
      setState(() => _selectedPlanTitle = plan.title);
      Navigator.pop(context, plan.title);
      return;
    }

    // Determine price
    final String priceStr = _billingCycle == 0
        ? plan.priceMonthly
        : plan.priceYearly;
    double amount = double.tryParse(priceStr) ?? 0.0;

    // Apply discount from backend
    double appliedDiscount = 0.0;
    if (plan.discountPercentage > 0) {
      appliedDiscount = plan.discountPercentage.toDouble();
      amount = amount * (1 - appliedDiscount / 100);
      amount = double.parse(amount.toStringAsFixed(2));
    }

    final params = PaymentParams(
      title: plan.title,
      amount: amount,
      currency: 'EGP',
      description: _billingCycle == 0 ? 'billing_monthly' : 'billing_yearly',
      isSubscription: true,
      planId: plan.id.toString(),
      originalAmount: double.tryParse(priceStr) ?? 0.0,
      discountPercentage: plan.discountPercentage,
    );

    // Navigate to Payment Flow
    AppRouter.navigateTo(
      context,
      Routes.paymentMethodSelection,
      arguments: params,
    );
  }

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  void _showAlreadySubscribedDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 26.w,
                    vertical: 28.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.r),
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.55),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.6),
                      width: 1.2,
                    ),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Icon
                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.08),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: SvgPicture.asset(
                          Assets.premium,
                          height: 34.sp,
                          width: 34.sp,
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(height: 22.h),

                      /// Title
                      Text(
                        'already_subscribed_title'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .4,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      /// Message
                      Text(
                        'already_subscribed_message'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          height: 1.7,
                          color: isDark
                              ? Colors.white.withOpacity(.85)
                              : Colors.black54,
                          fontFamily: 'Tajawal',
                        ),
                      ),

                      SizedBox(height: 26.h),

                      /// Button (Classy)
                      SizedBox(
                        width: double.infinity,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.35),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'ok'.tr(),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'subscription_plans'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          onPressed: () => Navigator.pop(context, _selectedPlanTitle),
        ),
      ),
      body: Stack(
        children: [
          // 1. Animated Background
          const Positioned.fill(child: AnimatedBackground()),

          // 2. Overlay Gradient for readability if needed (optional)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    children: [
                      SizedBox(height: 10.h),
                      _buildBillingToggle(),
                      SizedBox(height: 20.h),

                      // Horizontal Page View
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _plans.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            final isSelected = plan.title == _selectedPlanTitle;

                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;
                                if (_pageController.position.haveDimensions) {
                                  value = _pageController.page! - index;
                                  value = (1 - (value.abs() * 0.1)).clamp(
                                    0.9,
                                    1.0,
                                  );
                                } else {
                                  value = (index == _currentPage) ? 1.0 : 0.9;
                                }
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: _buildPlanCard(plan, isSelected, isDark),
                            );
                          },
                        ),
                      ),

                      // Indicators
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _plans.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            height: 8.h,
                            width: _currentPage == index ? 24.w : 8.w,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Center(
      child: Container(
        width: 250.w,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            _buildToggleOption(0, 'billing_monthly'.tr()),
            _buildToggleOption(
              1,
              'billing_yearly'.tr(),
              badge: 'save_percent'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(int index, String text, {String? badge}) {
    final bool isSelected = _billingCycle == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _billingCycle = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [AppColors.primary, AppColors.primaryLight]
                  : [Colors.transparent, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: isSelected ? Colors.white : Colors.white,
                ),
              ),
              if (badge != null && !isSelected)
                Positioned(
                  top: -18,
                  right: -5,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan, bool isSelected, bool isDark) {
    // Check if this is the current plan
    final userProvider = context.watch<UserProvider>();
    // Plan ID from backend is int, PlanModel id is int. UserModel currentPlanId is int.
    // If subscribed, match ID. If NOT subscribed/expired, match Free (ID 1).
    final bool isCurrentPlan = userProvider.isSubscribed
        ? (userProvider.user?.currentPlanId == plan.id)
        : (plan.id == 1);

    bool isFree =
        plan.priceMonthly == 'Free' ||
        (double.tryParse(plan.priceMonthly) == 0);

    String price = 'Free';
    String period = '';
    if (!isFree) {
      String rawPrice = _billingCycle == 0
          ? plan.priceMonthly
          : plan.priceYearly;
      double? val = double.tryParse(rawPrice);
      price = val != null ? val.toStringAsFixed(2) : rawPrice;
      period = _billingCycle == 0 ? 'month'.tr() : 'year'.tr();
    }

    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 5.w),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isSelected ? plan.color : Colors.white.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image / Header
                SizedBox(
                  height: 190.h,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Gradient based on Plan Color
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              plan.color.withOpacity(0.7),
                              plan.color2.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Image
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            plan.imagePath != null
                                ? Lottie.asset(
                                    plan.imagePath!,
                                    height: 120.h,
                                    fit: BoxFit.contain,
                                  )
                                : Icon(
                                    Icons.verified_user_outlined,
                                    size: 60.sp,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                            SizedBox(height: 8.h),
                            Text(
                              plan.getLocalizedTitle(context),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentPlan)
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'current_plan'.tr(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (plan.isBestValue)
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondaryDark,
                                  AppColors.warning2,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning2.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.warning2,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'best_value'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (plan.isPopular)
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primaryLight,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLight.withOpacity(
                                    0.5,
                                  ),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.primaryLight,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'most_popular'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (plan.getLocalizedDiscount(context)?.isNotEmpty ??
                          false)
                        Positioned(
                          top: 10.h,
                          left: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              plan.getLocalizedDiscount(context)!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 15.h,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (plan.discountPercentage > 0 && price != 'Free') ...[
                        Text(
                          '${((double.tryParse(price) ?? 0) * (1 - plan.discountPercentage / 100)).toStringAsFixed(0)} EGP',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.red,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$price EGP',
                          style: TextStyle(
                            fontSize: 18.sp,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ] else
                        Text(
                          price == 'Free' ? price.tr() : '$price EGP',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      if (price != 'Free')
                        Text(
                          period,
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                        ),
                    ],
                  ),
                ),

                // Free Limit Warning
                if (plan.price == '0' || plan.price == '0.00')
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.red, size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'plan_free_limit_desc'.tr(),
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Features
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(20.w),
                    itemCount: plan.getLocalizedFeatures(context).length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final features = plan.getLocalizedFeatures(context);
                      return Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: plan.color,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              features[index],
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Button
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCurrentPlan
                          ? null
                          : (isSelected ? null : () => _onPlanSelected(plan)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentPlan
                            ? Colors.green
                            : (isSelected ? Colors.grey : plan.color),
                        disabledBackgroundColor: isCurrentPlan
                            ? Colors.green.withOpacity(0.8)
                            : null,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 5,
                        shadowColor: plan.color.withOpacity(0.4),
                      ),
                      child: Text(
                        isCurrentPlan
                            ? 'current_plan'.tr()
                            : (isSelected
                                  ? 'selected'.tr()
                                  : 'subscribe_now'.tr()),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
