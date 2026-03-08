// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/typography.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/home/home_page.dart';
import 'package:servino_provider/features/bookings/my_bookings_page.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/services/update_service.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/core/ads/widgets/banner_ad_widget.dart';

import 'package:servino_provider/features/chat/pages/conversations_page.dart';

import 'package:servino_provider/features/profile/profile_page.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _pages = [
    const HomePage(),
    const MyBookingsPage(),
    const ConversationsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Check for in-app updates once when the main layout initializes
    UpdateService().checkForUpdate();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String activeIcon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _onTap(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: SvgPicture.asset(
                selected ? activeIcon : icon,
                height: 22,
                color: selected
                    ? (isDarkMode ? Colors.white : AppColors.primary)
                    : (isDarkMode
                          ? Colors.white.withOpacity(0.6)
                          : Colors
                                .black), // Keeping white as per user edit for inactive
              ),
            ),

            const SizedBox(height: 4),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: AppTypography.labelSmall.copyWith(
                // Changed to Small for better fit
                color: selected
                    ? (isDarkMode ? Colors.white : AppColors.primary)
                    : (isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10, // Explicit small size for compact layout
              ),
              child: Text(
                label.tr(),
                style: AppTypography.labelSmall.copyWith(
                  color: selected
                      ? (isDarkMode ? Colors.white : AppColors.primary)
                      : (isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 10, // Explicit small size for compact layout
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RE-WRITING _buildNavItem to be safer and closer to original but nicer:
  // I will use a Column approach as before but cleaner.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final userProvider = context.watch<UserProvider>();
    final isFreePlan = !userProvider.isSubscribed;

    return Scaffold(
      extendBody: true, // Important for glass effect to show content behind
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // 1. Animated Liquid Background
                const Positioned.fill(child: AnimatedBackground()),

                // 2. Main Content
                SafeArea(
                  bottom: false,
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable swipe if desired, or keep default
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    children: _pages,
                  ),
                ),

                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 5, // Lifted up slightly
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFreePlan) BannerAdWidget(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: -5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildNavItem(
                                    index: 0,
                                    icon: Assets.home,
                                    activeIcon: Assets.homeAt,
                                    label: 'nav_home',
                                  ),
                                  _buildNavItem(
                                    index: 1,
                                    icon: Assets.booking,
                                    activeIcon: Assets.bookingAt,
                                    label: 'nav_bookings',
                                  ),
                                  _buildNavItem(
                                    index: 2,
                                    icon: Assets.chath,
                                    activeIcon: Assets.chatAt,
                                    label: 'nav_chat',
                                  ),
                                  _buildNavItem(
                                    index: 3,
                                    icon: Assets.person,
                                    activeIcon: Assets.personAt,
                                    label: 'nav_profile',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ], // End Stack children
            ), // End Stack
          ), // End Expanded
        ], // End Column children
      ), // End Column
    );
  }
}
