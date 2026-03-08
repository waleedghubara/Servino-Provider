// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/features/chat/chat_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:servino_provider/features/bookings/booking_helper.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/bookings/data/repo/booking_repo.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';

import 'package:servino_provider/core/utils/url_helper.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';
import 'package:servino_provider/core/ads/ads_manager.dart'; // Added import

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late String _status;
  final BookingRepository _repository = BookingRepository(
    api: DioConsumer(dio: Dio()),
  );
  String? _loadingAction;

  Future<void> _performAction(
    String action,
    Future<void> Function() task,
  ) async {
    if (_loadingAction != null) return;
    setState(() => _loadingAction = action);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _loadingAction = null);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _status = widget.booking['status'];
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _repository.updateStatus(
        bookingId: int.parse(widget.booking['id'].toString()),
        status: newStatus,
      );
      if (mounted) {
        setState(() {
          _status = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'status_updated_msg'.tr(
                args: [BookingHelper.getLocalizedStatus(newStatus)],
              ),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool get _isPending {
    final s = _status.toLowerCase();
    return s == 'pending' || _status == 'قيد الانتظار';
  }

  bool get _isConfirmed {
    final s = _status.toLowerCase();
    return s == 'confirmed' || _status == 'مؤكد';
  }

  bool get _isOnTheWay {
    final s = _status.toLowerCase();
    return s == 'on the way' || _status == 'في الطريق';
  }

  bool get _isArrived {
    final s = _status.toLowerCase();
    return s == 'arrived' || _status == 'وصل' || _status == 'وصلت';
  }

  bool get _isCompleted {
    final s = _status.toLowerCase();
    return s == 'completed' || _status == 'مكتمل' || s == 'finished';
  }

  bool get _isRejected {
    final s = _status.toLowerCase();
    return s == 'rejected' ||
        _status == 'مرفوض' ||
        s == 'declined' ||
        s == 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.booking['type'].toString().toLowerCase();

    final bool isComingToMe =
        type == 'coming to me' ||
        widget.booking['type'] == 'موعد للقدوم اليا'; // Keep Arabic as is
    final bool isConsultation =
        type == 'consultation' || widget.booking['type'] == 'استشاره';
    final bool isGoingToHim =
        type == 'going to him' || widget.booking['type'] == 'موعد للقدوم اليه';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E2A47) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, isDark, textColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        title: 'booking_info'.tr(),
                        cardColor: cardColor,
                        textColor: textColor,
                        children: [
                          _buildDetailRow(
                            Icons.calendar_month_rounded,
                            'label_date'.tr(),
                            DateFormat(
                              'd MMM y',
                              context.locale.languageCode,
                            ).format(
                              DateTime.parse(
                                '${widget.booking['date']} ${widget.booking['time']}',
                              ),
                            ),
                            textColor,
                            subTextColor,
                          ),
                          _buildDivider(isDark),
                          _buildDetailRow(
                            Icons.access_time_filled_rounded,
                            'label_time'.tr(),
                            DateFormat.jm(context.locale.languageCode).format(
                              DateTime.parse(
                                '${widget.booking['date']} ${widget.booking['time']}',
                              ),
                            ),
                            textColor,
                            subTextColor,
                          ),
                          if (!isComingToMe && !isGoingToHim) ...[
                            _buildDivider(isDark),
                            _buildDetailRow(
                              Icons.attach_money_rounded,
                              'label_price'.tr(),
                              widget.booking['price'] ?? '',
                              AppColors.success,
                              subTextColor,
                              isPrice: true,
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: 16.h),

                      _buildInfoCard(
                        context,
                        title: 'customer_info'.tr(),
                        cardColor: cardColor,
                        textColor: textColor,
                        children: [
                          _buildDetailRow(
                            Icons.phone_rounded,
                            'label_phone'.tr(),
                            widget.booking['phone'] ?? '',
                            textColor,
                            subTextColor,
                          ),
                          if (widget.booking['email'] != null) ...[
                            _buildDivider(isDark),
                            _buildDetailRow(
                              Icons.email_rounded,
                              'label_email'.tr(),
                              widget.booking['email'],
                              textColor,
                              subTextColor,
                            ),
                          ],
                          _buildDivider(isDark),
                          _buildDetailRow(
                            Icons.location_on_rounded,
                            'label_location'.tr(),
                            widget.booking['location'] ?? '',
                            textColor,
                            subTextColor,
                          ),
                        ],
                      ),

                      if (isComingToMe && !_isPending && !_isRejected) ...[
                        SizedBox(height: 16.h),
                        _buildTrackingSection(
                          context,
                          cardColor,
                          textColor,
                          subTextColor,
                        ),
                      ],

                      SizedBox(height: 30.h),
                      _buildActions(
                        context,
                        isConsultation,
                        isComingToMe,
                        isGoingToHim,
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ), // CustomScrollView
        ), // Scaffold
      ],
    ); // Stack
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    Color statusColor = BookingHelper.getStatusColor(_status);
    // Adjust opacity for better visibility if it's too transparent
    if (statusColor.opacity < 0.2) statusColor = statusColor.withOpacity(0.2);

    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      leading: InkWell(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: textColor,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8.r),
          height: 40.h,
          width: 40.h,
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.report_gmailerrorred_rounded,
              color: AppColors.error,
              size: 24.sp,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image/Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary2.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Decorative Circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  Hero(
                    tag: 'avatar_${widget.booking['id']}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55.r,
                        backgroundColor: Colors.white,
                        child:
                            UrlHelper.getAbsoluteUrl(
                              widget.booking['image'],
                            ).isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  UrlHelper.getAbsoluteUrl(
                                    widget.booking['image'],
                                  ),
                                  width: 110.r,
                                  height: 110.r,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Text(
                                    widget.booking['name'][0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 40.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                widget.booking['name'][0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 40.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.booking['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          BookingHelper.getLocalizedType(
                            widget.booking['type'],
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          BookingHelper.getLocalizedStatus(_status),
                          style: TextStyle(
                            color: BookingHelper.getStatusTextColor(_status),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
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

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required Color cardColor,
    required Color textColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: textColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subTextColor, {
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: isPrice
                ? AppColors.success.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isPrice ? AppColors.success : AppColors.primary,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Divider(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        height: 1,
      ),
    );
  }

  Widget _buildTrackingSection(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            'tracking_title'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: textColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStep(
                'tracking_confirmed_title'.tr(),
                'tracking_confirmed_subtitle'.tr(),
                true,
                false,
              ),
              _buildStep(
                'tracking_on_way_title'.tr(),
                'tracking_on_way_subtitle'.tr(),
                _isOnTheWay || _isArrived || _isCompleted,
                false,
              ),
              _buildStep(
                'tracking_arrived_title'.tr(),
                'tracking_arrived_subtitle'.tr(),
                _isArrived || _isCompleted,
                false,
              ),
              _buildStep(
                'tracking_completed_title'.tr(),
                'tracking_completed_subtitle'.tr(),
                _isCompleted,
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String title, String subtitle, bool isActive, bool isLast) {
    Color textColor = isActive ? AppColors.success : Colors.grey;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: isActive ? AppColors.success : Colors.grey.shade400,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isActive
                    ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: isActive ? AppColors.success : Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.success : Colors.grey,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: textColor),
                ),
                if (!isLast) SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    bool isConsultation,
    bool isComingToMe,
    bool isGoingToHim,
  ) {
    if (_isPending) {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'action_reject'.tr(),
              AppColors.error,
              Colors.white,
              () => _performAction('reject', () => _updateStatus('rejected')),
              isOutlined: true,
              isLoading: _loadingAction == 'reject',
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildButton(
              'action_accept'.tr(),
              AppColors.success,
              Colors.white,
              () => _performAction('accept', () => _updateStatus('confirmed')),
              isLoading: _loadingAction == 'accept',
            ),
          ),
        ],
      );
    }

    if (isConsultation) {
      if (_isCompleted) {
        return const SizedBox.shrink();
      }
      // For ANY other status (Confirmed, Arrived, etc - even if erroneous), show Chat.
      // This prevents falling through to 'Tracking' buttons.
      return _buildButton(
        'action_start_consultation'.tr(),
        AppColors.primary,
        Colors.white,
        _openChat,
        icon: Icons.chat,
      );
    }

    if (isGoingToHim &&
        (_isConfirmed || _isOnTheWay || _isArrived || _isCompleted)) {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'action_contact'.tr(),
              AppColors.primary,
              Colors.white,
              _openChat,
              icon: Icons.chat,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildButton(
              'action_remind'.tr(),
              AppColors.warning,
              Colors.white,
              () => _performAction('remind', () async {
                try {
                  await _repository.sendReminder(widget.booking['id']);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('reminder_sent_success'.tr()),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('reminder_failed'.tr()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }),
              icon: Icons.notifications_active,
              isLoading: _loadingAction == 'remind',
            ),
          ),
        ],
      );
    }

    if (isComingToMe && !_isRejected) {
      return _buildButton(
        _getTrackingBtnText(),
        _isCompleted ? Colors.grey : AppColors.primary,
        Colors.white,
        _isCompleted ? null : () => _performAction('tracking', _advanceStatus),
        icon: _getTrackingIcon(),
        isLoading: _loadingAction == 'tracking',
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildButton(
    String label,
    Color bg,
    Color fg,
    VoidCallback? onTap, {
    bool isOutlined = false,
    IconData? icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 54.h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : bg,
          foregroundColor: isOutlined ? bg : fg,
          disabledBackgroundColor: bg.withOpacity(0.7),
          elevation: isOutlined ? 0 : 5,
          shadowColor: bg.withOpacity(0.4),
          side: isOutlined
              ? BorderSide(color: bg, width: 1.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.sp,
                height: 24.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openChat() {
    final type = widget.booking['type'].toString().toLowerCase();

    // Ensure absolute URL for chat
    final image = UrlHelper.getAbsoluteUrl(widget.booking['image']);
    final providerImage = image.isNotEmpty ? image : ''; // Fallback

    void navigateToChat() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userName: widget.booking['name'],
            initialArguments: {
              'providerName': widget.booking['name'],
              'providerImage': providerImage,
              'userId': widget.booking['user_id'].toString(),
              'bookingId': widget.booking['id'],
              'isConsultation':
                  type == 'consultation' || widget.booking['type'] == 'استشاره',
              // Add other relevant data if needed
              'type': 'booking_request', // To maybe trigger init logic
            },
          ),
        ),
      );
    }

    final isSubscribed = context.read<UserProvider>().isSubscribed;
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
  }

  Future<void> _advanceStatus() async {
    if (_isConfirmed) {
      await _updateStatus('On The Way');
    } else if (_isOnTheWay) {
      await _updateStatus('Arrived');
    } else if (_isArrived) {
      await _updateStatus('Completed');
    }
  }

  String _getTrackingBtnText() {
    if (_isConfirmed) return 'tracking_btn_on_way'.tr();
    if (_isOnTheWay) return 'tracking_btn_arrived'.tr();
    if (_isArrived) return 'tracking_btn_complete'.tr();
    return 'tracking_btn_finished'.tr();
  }

  IconData _getTrackingIcon() {
    if (_isConfirmed) return Icons.directions_car;
    if (_isOnTheWay) return Icons.location_on;
    if (_isArrived) return Icons.flag;
    return Icons.check_circle;
  }
}
