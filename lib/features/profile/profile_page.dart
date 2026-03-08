// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/support/support_page.dart';
import 'package:servino_provider/core/theme/theme_manager.dart';
import 'package:servino_provider/features/profile/personal_information_page.dart';
import 'package:servino_provider/features/profile/privacy_policy_page.dart';
import 'package:servino_provider/features/profile/terms_of_use_page.dart';
import 'package:servino_provider/features/subscription/subscription_page.dart';

import 'package:provider/provider.dart';
import 'package:servino_provider/features/auth/data/models/user_model.dart';
import 'package:servino_provider/core/providers/user_provider.dart';

import 'package:servino_provider/features/auth/login_page.dart';
import 'package:servino_provider/core/routes/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    // Determine current plan locally based on Provider
    // Mapping: 1=Free, 2=Pro, 3=VIP (Adjust as needed)
    String currentPlanKey = 'plan_free';
    if (userProvider.isSubscribed) {
      final pid = user?.currentPlanId ?? 1;
      if (pid == 3)
        currentPlanKey = 'plan_vip';
      else if (pid == 2)
        currentPlanKey = 'plan_pro';
      else if (pid == 1)
        currentPlanKey = 'plan_free';
      else
        currentPlanKey = 'plan_pro'; // Fallback or handle unknown
    } else {
      currentPlanKey = 'plan_free';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Animated Background (Consistent with other pages)
          const Positioned.fill(child: AnimatedBackground()),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  // Profile Header
                  _buildProfileHeader(context, isDark, user),
                  SizedBox(height: 40.h),

                  // Menu Options
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.profile,
                    title: 'nav_profile'.tr(), // 'Profile'
                    subtitle: 'edit_personal_details'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInformationPage(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Subscription (Updated)
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.premium,
                    title: 'my_plan'.tr(),
                    subtitle: currentPlanKey.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionPage(
                            currentPlanTitle: currentPlanKey,
                          ),
                        ),
                      );
                    },
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: currentPlanKey == 'plan_free'
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: currentPlanKey == 'plan_free'
                              ? Colors.grey
                              : Colors.amber,
                        ),
                      ),
                      child: Text(
                        currentPlanKey.tr(),
                        style: TextStyle(
                          color: currentPlanKey == 'plan_free'
                              ? Colors.grey
                              : Colors.amber[700],
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.supportSvg,
                    title: 'support_page_title'.tr(),
                    subtitle: 'get_help_and_support'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportPage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Contact Us Page
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets
                        .profile, // Will fallback to outline/message if missing, or maybe re-use another icon or pass Assets.message. Wait the icon is expecting SVG asset. Just pass Assets.supportSvg if we don't have a contact SVG. Actually let's use the default icon behavior by passing an existing SVG.
                    title: 'تواصل معنا', // 'contact_us'.tr()
                    subtitle: 'تليجرام، واتساب والمزيد',
                    onTap: () {
                      Navigator.pushNamed(context, Routes.contactUs);
                    },
                  ),
                  SizedBox(height: 16.h),
                  // Settings Section
                  Align(
                    alignment: context.locale.languageCode == 'ar'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        'settings'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Language
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.language,
                    title: 'language'.tr(),
                    subtitle: context.locale.languageCode == 'ar'
                        ? 'العربية'
                        : 'English',
                    onTap: () => _showLanguageBottomSheet(context),
                  ),
                  SizedBox(height: 16.h),

                  // Theme
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: isDark ? Assets.darkmode : Assets.lightmode,
                    title: 'theme'.tr(),
                    subtitle: isDark ? 'dark_mode'.tr() : 'light_mode'.tr(),
                    trailing: Switch(
                      value: isDark,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        final newMode = val ? ThemeMode.dark : ThemeMode.light;
                        ThemeManager().setThemeMode(newMode);
                      },
                    ),
                    onTap: () {
                      final newMode = !isDark
                          ? ThemeMode.dark
                          : ThemeMode.light;
                      ThemeManager().setThemeMode(newMode);
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Legal Section
                  Align(
                    alignment: context.locale.languageCode == 'ar'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        'legal'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Privacy Policy
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.privacy,
                    title: 'privacy_policy'.tr(),
                    subtitle: 'privacy_policy_subtitle'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Terms of Use
                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.description,
                    title: 'terms_of_use'.tr(),
                    subtitle: 'terms_of_use_subtitle'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfUsePage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),

                  _buildMenuTile(
                    context,
                    isDark,
                    icon: Assets.logout,
                    title: 'logout'.tr(),
                    subtitle: 'sign_out_subtitle'.tr(),
                    isDestructive: true,
                    onTap: () {
                      context.read<UserProvider>().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  SizedBox(height: 70.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    UserModel? user,
  ) {
    // 1. Determine Plan Status
    final bool isSubscribed = user?.isSubscribed ?? false;
    final int planId = user?.currentPlanId ?? 0;

    // 2. Select Frame
    // ID 3 = VIP (Gold Frame)
    // ID 2 = Pro  (No Frame currently, or add Pro asset later)
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

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Avatar Container
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  // Show border if NOT using a frame (or if not subscribed)
                  color: (isSubscribed && frameAsset != null)
                      ? Colors.transparent
                      : AppColors.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50.r,
                backgroundImage: imageProvider,
                backgroundColor: Colors.grey.shade200,
              ),
            ),

            // Generated Frame Overlay
            // Generated Frame Overlay
            if (frameAsset != null)
              Positioned.fill(
                child: Transform.scale(
                  scale: 1.7,
                  child: Image.asset(frameAsset, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user?.name ?? 'Waleed Ghubara',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isSubscribed) ...[
              SizedBox(width: 8.w),
              Icon(Icons.verified, color: Colors.blue, size: 20.sp),
            ],
          ],
        ),
        SizedBox(height: 4.h),
        if (user?.description != null && user!.description!.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              user.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.grey,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    bool isDark, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(icon, width: 24.w, height: 24.h),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDestructive
                              ? Colors.red
                              : (isDark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white60 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.sp,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final List<Map<String, dynamic>> languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'comingSoon': false},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'comingSoon': false},
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'comingSoon': true},
      {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'comingSoon': true},
      {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'comingSoon': true},
      {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'comingSoon': true},
      {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'comingSoon': true},
      {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵', 'comingSoon': true},
      {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺', 'comingSoon': true},
      {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹', 'comingSoon': true},
      {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'comingSoon': true},
      {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷', 'comingSoon': true},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: 600.h,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Text(
                'select_language'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return _buildLanguageOption(
                      context,
                      lang['name']!,
                      lang['code']!,
                      lang['flag']!,
                      isDark,
                      lang['comingSoon'] as bool,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String code,
    String flag,
    bool isDark,
    bool comingSoon,
  ) {
    final isSelected = context.locale.languageCode == code;
    return GestureDetector(
      onTap: comingSoon
          ? null
          : () {
              context.setLocale(Locale(code));
              Navigator.pop(context);
            },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (comingSoon
                    ? (isDark
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05))
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: comingSoon ? 0.5 : 1.0,
              child: Text(flag, style: TextStyle(fontSize: 24.sp)),
            ),
            SizedBox(width: 16.w),
            Opacity(
              opacity: comingSoon ? 0.5 : 1.0,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const Spacer(),
            if (comingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  context.locale.languageCode == 'ar'
                      ? 'قريباً'
                      : 'Coming soon',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}
