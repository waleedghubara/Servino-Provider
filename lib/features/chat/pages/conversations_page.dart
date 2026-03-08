// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_provider/core/model/message_model.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/theme/typography.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/chat/chat_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/features/chat/data/repo/chat_repo.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/core/ads/ads_manager.dart';
import 'package:servino_provider/core/utils/url_helper.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  late ChatRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ChatRepository(api: DioConsumer(dio: Dio()));
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    // 1. Load Local Data First (Instant)
    try {
      final localData = await _repository.getLocalConversations();
      if (mounted && localData.isNotEmpty) {
        setState(() {
          _conversations = localData;
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint('Error loading local conversations: $e');
    }

    // 2. Fetch Remote Data (Background Update)
    try {
      final data = await _repository.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // debugPrint('Error fetching conversations: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((chat) {
      final name = chat['name'].toString().toLowerCase();
      final lastMessage = chat['lastMessage'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. Animated Background
          const Positioned.fill(child: AnimatedBackground()),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchConversations,
                    color: AppColors.primary,
                    child: _isLoading && _conversations.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredConversations.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 150.h),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.chatAt,
                                    width: 100.w,
                                    height: 100.h,
                                  ),
                                  SizedBox(height: 16.h),
                                  Center(
                                    child: Text(
                                      'no_conversations_found'.tr(),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              10.h,
                              16.w,
                              100.h,
                            ), // Bottom padding for nav bar
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, index) {
                              final chat = _filteredConversations[index];
                              return _buildConversationItem(chat, isDark);
                            },
                          ),
                  ),
                ),
              ],
            ),
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
          'nav_chat'.tr(),
          style: AppTypography.h2.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
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
                hintText: 'search_conversations'.tr(),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),

                // يشيل أي لون أو شكل افتراضي
                filled: false,
                fillColor: Colors.transparent,

                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,

                contentPadding: EdgeInsets.zero, // لو مش عايز مسافات زيادة
              ),
              cursorColor: isDark ? Colors.white : AppColors.textPrimary,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
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
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> chat, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  void navigateToChat() async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          userName: chat['name'],
                          initialArguments: {
                            'providerName': chat['name'],
                            'providerImage': UrlHelper.getAbsoluteUrl(
                              chat['image'],
                            ),
                            if (chat['bookingId'] != null)
                              'bookingId': chat['bookingId'],
                            'userId': chat['id'].toString(),
                            'isConsultation': false,
                          },
                        ),
                      ),
                    );
                    if (mounted) {
                      setState(() {
                        chat['unreadCount'] = 0;
                      });
                    }
                    _fetchConversations();
                  }

                  final isSubscribed = context
                      .read<UserProvider>()
                      .isSubscribed;
                  if (!isSubscribed) {
                    bool earnedReward = false;
                    AdsManager.instance.showRewardedAd(
                      onUserEarnedReward: (reward) {
                        earnedReward = true;
                      },
                      onAdClosed: () {
                        if (earnedReward) {
                          navigateToChat();
                        }
                      },
                      onAdFailed: () {
                        navigateToChat();
                      },
                    );
                  } else {
                    navigateToChat();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28.r,
                            backgroundImage: NetworkImage(
                              (chat['image'] != null &&
                                      chat['image'].toString().isNotEmpty)
                                  ? UrlHelper.getAbsoluteUrl(chat['image'])
                                  : 'https://randomuser.me/api/portraits/men/1.jpg',
                            ),
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    chat['name'],
                                    style: AppTypography.h5.copyWith(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTime(chat['time']),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              MessageModel.getSnippet(
                                MessageModel.parseType(
                                  chat['lastMessageType'] ?? chat['type'],
                                  chat['lastMessage'] ?? chat['content'],
                                ),
                                chat['lastMessage'] ?? chat['content'] ?? '',
                              ),
                              style: AppTypography.bodyMedium.copyWith(
                                color:
                                    (chat['unreadCount'] is int
                                            ? chat['unreadCount']
                                            : int.tryParse(
                                                    chat['unreadCount']
                                                        .toString(),
                                                  ) ??
                                                  0) >
                                        0
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.textPrimary)
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                fontWeight:
                                    (chat['unreadCount'] is int
                                            ? chat['unreadCount']
                                            : int.tryParse(
                                                    chat['unreadCount']
                                                        .toString(),
                                                  ) ??
                                                  0) >
                                        0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

  // Parse time safely
  String _formatTime(dynamic time) {
    DateTime dt;
    if (time is String) {
      dt = DateTime.tryParse(time) ?? DateTime.now();
    } else if (time is DateTime) {
      dt = time;
    } else {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) {
      return DateFormat.jm().format(dt);
    } else if (today.difference(msgDate).inDays < 7) {
      return DateFormat.E().format(dt); // Mon, Tue...
    } else {
      return DateFormat.MMMd().format(dt); // Jan 1, Feb 12...
    }
  }
}
