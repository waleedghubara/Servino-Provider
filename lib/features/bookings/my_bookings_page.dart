// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/bookings/booking_details_page.dart';
import 'package:servino_provider/features/bookings/booking_helper.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/features/bookings/data/repo/booking_repo.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/features/bookings/widgets/booking_limit_dialog.dart';
import 'package:servino_provider/features/subscription/subscription_page.dart';
import 'package:servino_provider/core/ads/ads_manager.dart';
import 'package:servino_provider/core/ads/widgets/banner_ad_widget.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  String _searchQuery = '';

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Repository
  late final BookingRepository _repository;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _repository = BookingRepository(api: DioConsumer(dio: Dio()));
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final bookings = await _repository.getBookings();
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _filteredBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterBookings(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBookings = _allBookings;
      } else {
        _filteredBookings = _allBookings.where((booking) {
          return booking['name'].toString().toLowerCase().contains(
            query.toLowerCase(),
          );
        }).toList();
      }
    });
  }

  List<Map<String, dynamic>> _getBookingsByType(String typeKey) {
    return _filteredBookings.where((booking) {
      final bType = booking['type'].toString().toLowerCase();
      if (typeKey == 'consultation') {
        return bType == 'consultation' || bType == 'استشاره';
      } else if (typeKey == 'at_my_location') {
        // Label is "At My Location", so we want API type "Going to Him"
        return bType == 'going to him' || bType == 'موعد للقدوم اليه';
      } else if (typeKey == 'at_client_location') {
        // Label is "At Client's Location", so we want API type "Coming to Me"
        return bType == 'coming to me' || bType == 'موعد للقدوم اليا';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackground()),
            SafeArea(
              child: Column(
                children: [
                  // 1. Animated Header
                  _buildHeader(isDark),

                  // 2. TabBar
                  _buildTabBar(isDark),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchBookings,
                      color: AppColors.primary,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingList('consultation'),
                          _buildBookingList('at_my_location'),
                          _buildBookingList('at_client_location'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 7.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        padding: EdgeInsets.all(4.w),
        labelPadding: EdgeInsets.all(4.w),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(7.r),
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
        labelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Tajawal',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Tajawal',
        ),

        tabs: [
          _buildPremiumTab(
            Icons.headset_mic_rounded,
            'bookings_tab_consultation'.tr(),
          ),
          _buildPremiumTab(
            Icons.home_work_rounded,
            'bookings_tab_going_to_him'.tr(), // This is the "إلي" label
          ),
          _buildPremiumTab(
            Icons.directions_run_rounded,
            'bookings_tab_coming_to_me'.tr(), // This is the "إليه" label
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: _buildTitleBar(isDark),
        secondChild: _buildSearchBar(isDark),
        crossFadeState: _isSearching
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
      ),
    );
  }

  Widget _buildTitleBar(bool isDark) {
    return Row(
      children: [
        Text(
          'nav_bookings'.tr(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : AppColors.textPrimary,
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
                _filterBookings('');
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontFamily: 'Tajawal',
              ),
              decoration: InputDecoration(
                hintText: 'bookings_search_hint'.tr(),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              cursorColor: isDark ? Colors.white : AppColors.textPrimary,
              onChanged: _filterBookings,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close,
                color: const Color.fromARGB(255, 255, 17, 0),
                size: 20.sp,
              ),
              onPressed: () {
                _searchController.clear();
                _filterBookings('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tab(
      height: 36.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: isDark ? AppColors.surface : Colors.black,
          ),

          Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.surface : Colors.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookings = _getBookingsByType(type);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading bookings'),
                TextButton(onPressed: _fetchBookings, child: Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }

    if (bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 150.h),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(Assets.bookingchats, height: 100.h),
                SizedBox(height: 16.h),
                Text(
                  'bookings_empty'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.surface : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final isSubscribed = context.watch<UserProvider>().isSubscribed;

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: bookings.length,
      separatorBuilder: (c, i) {
        // Show an ad after every 2 items (indices 1, 3, 5, etc.) if not subscribed
        if (!isSubscribed && (i + 1) % 2 == 0) {
          return Column(
            children: [
              SizedBox(height: 16.h),
              const BannerAdWidget(),
              SizedBox(height: 16.h),
            ],
          );
        }
        return SizedBox(height: 16.h);
      },
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isComingToMe =
        booking['type'].toString().toLowerCase() == 'coming to me' ||
        booking['type'].toString().contains('اليا');
    final isGoingToHim =
        booking['type'].toString().toLowerCase() == 'going to him' ||
        booking['type'].toString().contains('اليه');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final userProvider = context.read<UserProvider>();
            final user = userProvider.user;

            // Check for Free Plan Booking Limit (4 bookings)
            final bool isSubscribed = user?.isSubscribed ?? false;
            final int totalRequests = user?.totalRequests ?? 0;

            if (!isSubscribed && totalRequests >= 4) {
              showDialog(
                context: context,
                builder: (context) => BookingLimitDialog(
                  onSubscribe: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionPage(),
                      ),
                    );
                  },
                ),
              );
              return;
            }

            void navigateToDetails() async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailsPage(booking: booking),
                ),
              );
              _fetchBookings();
            }

            if (!isSubscribed) {
              bool earnedReward = false;
              AdsManager.instance.showRewardedAd(
                onUserEarnedReward: (reward) {
                  earnedReward = true;
                },
                onAdClosed: () {
                  if (earnedReward) {
                    navigateToDetails();
                  }
                },
                onAdFailed: () {
                  // Fallback: let them in if an ad isn't available
                  navigateToDetails();
                },
              );
            } else {
              navigateToDetails();
            }
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              children: [
                // Header Row: Avatar + Name + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'avatar_${booking['id']}',
                      child: Container(
                        width: 52.w,
                        height: 52.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26.r,
                          backgroundColor: AppColors.primary.withOpacity(0.05),
                          child: booking['image'] != null
                              ? ClipOval(
                                  child: Image.network(
                                    booking['image'],
                                    width: 52.w,
                                    height: 52.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        booking['name'][0].toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  booking['name'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['name'],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.surface
                                  : AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                child: Text(
                                  BookingHelper.getLocalizedType(
                                    booking['type'],
                                  ),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(booking['status']),
                  ],
                ),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    height: 1,
                    thickness: 1,
                  ),
                ),

                // Info Row: Time & Date left, Price right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14.sp,
                          color: isDark
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          DateFormat(
                            'd MMM y',
                            context.locale.languageCode,
                          ).format(
                            DateTime.parse(
                              '${booking['date']} ${booking['time']}',
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark
                                ? AppColors.surface
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14.sp,
                          color: isDark
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          DateFormat.jm(context.locale.languageCode).format(
                            DateTime.parse(
                              '${booking['date']} ${booking['time']}',
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark
                                ? AppColors.surface
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!isComingToMe && !isGoingToHim)
                      Text(
                        booking['price'],
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    if (isComingToMe || isGoingToHim)
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                          ),
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.surface,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.sp,
                          color: isDark
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: BookingHelper.getStatusColor(status),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        BookingHelper.getLocalizedStatus(status),
        style: TextStyle(
          color: BookingHelper.getStatusTextColor(status),
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
