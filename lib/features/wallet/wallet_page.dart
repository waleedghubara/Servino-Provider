// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:servino_provider/core/theme/colors.dart';

import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/core/theme/assets.dart'; // Import Assets
import 'package:animate_do/animate_do.dart';

import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/wallet/data/repo/wallet_repo.dart';
import 'package:servino_provider/features/wallet/data/models/wallet_transaction_model.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  late WalletRepository _repo;

  // Real Data State
  String _balance = '0.00';
  String _currency = 'EGP';
  List<WalletTransactionModel> _transactions = [];
  bool _isLoading = true;

  // Dynamic Controllers
  final Map<String, TextEditingController> _controllers = {};

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'vodafone_cash',
      'name': 'vodafone_cash',
      'image': Assets.vodafoneCash,
      'fields': ['wallet_number'],
    },
    {
      'id': 'instapay',
      'name': 'instapay',
      'image': Assets.instapay,
      'fields': ['instapay_address'],
    },
    {
      'id': 'bank_transfer',
      'name': 'bank_transfer',
      'image': Assets.bankTransfer,
      'fields': ['bank_name', 'account_holder', 'iban'],
    },
    {
      'id': 'paypal',
      'name': 'paypal',
      'image': Assets.paypal,
      'fields': ['paypal_email'],
    },
    {
      'id': 'binance',
      'name': 'binance',
      'image': Assets.binance,
      'fields': ['binance_id'],
    },
    {
      'id': 'other',
      'name': 'other',
      'image': '',
      'fields': ['method_name', 'review_details'],
    },
  ];

  Map<String, dynamic>? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repo = WalletRepository(api: DioConsumer(dio: Dio()));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final balanceData = await _repo.getBalance();
      final txns = await _repo.getTransactions();

      if (mounted) {
        setState(() {
          _balance = balanceData['balance'].toString();
          _currency = balanceData['currency'] ?? 'EGP';
          _transactions = txns;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _showMethodSelection(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 600.h,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          border: Border(
            top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),

            Text(
              "select_method".tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Tajawal',
              ),
            ),

            SizedBox(height: 20.h),

            Expanded(
              child: ListView.separated(
                itemCount: _methods.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final method = _methods[index];
                  final isSelected = _selectedMethod?['id'] == method['id'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMethod = method;
                        _initializeControllers(method['fields']);
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[50]),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white10 : Colors.grey[300]!),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 50.w,
                            height: 50.h,
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: method['image'].isNotEmpty
                                ? Center(
                                    child: Image.asset(
                                      method['image'],
                                      width: 100.w,
                                      height: 100.h,
                                    ),
                                  )
                                : Center(
                                    child: SvgPicture.asset(
                                      Assets.wallet,
                                      width: 24.sp,
                                      height: 24.sp,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            method['name'].toString().tr(),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeControllers(List<String> fields) {
    _controllers.clear();
    for (var field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  void _submitRequest() async {
    if (_selectedMethod == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('please_fill_all_fields'.tr())));
      return;
    }

    // Collect Details
    String methodId = _selectedMethod!['id'];
    Map<String, String> detailsMap = {'method': methodId};
    _controllers.forEach((key, controller) {
      detailsMap[key] = controller.text;
    });

    // Simple string representation for now, or JSON encode it
    String detailsString = detailsMap.entries
        .map((e) => "${e.key}: ${e.value}")
        .join(', ');

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('invalid_amount'.tr())));
      return;
    }

    try {
      // Show Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      await _repo.requestWithdrawal(amount: amount, details: detailsString);

      Navigator.pop(context); // Close Loading

      // Success
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(context),
      );

      // Refresh Data
      _loadData();
    } catch (e) {
      Navigator.pop(context); // Close Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _buildSuccessDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30.r,
              backgroundColor: Colors.green.withOpacity(0.1),
              child: SvgPicture.asset(
                Assets.successSvg,

                width: 35.sp,
                height: 35.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "request_submitted".tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "request_submitted_desc".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Go back to Home
                  // Reset form if needed
                  setState(() {
                    _amountController.clear();
                    _selectedMethod = null;
                    _controllers.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  "ok".tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20.sp,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[100],
                          padding: EdgeInsets.all(8.r),
                        ),
                      ),
                      Text(
                        "my_wallet".tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      SizedBox(width: 40.w), // Spacer
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Balance Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildBalanceCard(isDark),
                ),

                SizedBox(height: 24.h),

                // Tabs
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white70
                        : AppColors.textSecondary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      fontFamily: 'Tajawal',
                    ),
                    tabs: [
                      Tab(text: "request_withdrawal".tr()),
                      Tab(text: "withdrawal_history".tr()),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Request Withdrawal
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        child: _buildWithdrawalForm(isDark),
                      ),

                      // Tab 2: History
                      _buildHistoryList(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height:
                400.h, // Fixed height to allow centering but kept scrollable
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(Assets.wallet, width: 60.w, height: 60.h),
                  SizedBox(height: 16.h),
                  Text(
                    "bookings_empty".tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final req = _transactions[index];
          // Determine Color based on status
          Color statusColor = Colors.orange;
          final s = req.status.toLowerCase();
          if (s == 'completed' || s == 'approved' || s == 'approve') {
            statusColor = Colors.green;
          }
          if (s == 'failed' ||
              s == 'rejected' ||
              s == 'reject' ||
              s == 'cancelled' ||
              s == 'canceled' ||
              s == '_status' ||
              s == 'mlghi' ||
              s == 'ملغي' ||
              s.isEmpty) {
            statusColor = Colors.red;
          }

          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildDescriptionLines(
                          req.description,
                          req.typeTranslated,
                          isDark,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          req.date,
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w), // Add spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${req.amount} ${'currency_egy'.tr()}",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'XBFont_ENG',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          req.statusTranslated,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          image: DecorationImage(
            image: AssetImage(Assets.walletBalanceBg),
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.color,
            ),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF6C63FF))
                  .withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Container(
            // Gradient Overlay to ensure text readability
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "current_balance".tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _balance, // Dynamic value
                      style: TextStyle(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontFamily:
                            'XBFont_ENG', // Or user preferred numeral font
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _currency, // EGP or RS
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'XBFont_ENG',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "last_updated_now".tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDescriptionLines(
    String description,
    String typeTranslated,
    bool isDark,
  ) {
    if (description.isEmpty) {
      return [
        Text(
          typeTranslated,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Tajawal',
          ),
        ),
      ];
    }

    // Split by comma+space or just comma if space is missing
    List<String> lines = description.split(RegExp(r',\s*'));

    return lines.map((line) {
      return Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: Text(
          line.trim(),
          style: TextStyle(
            fontSize: 13.sp, // Slightly smaller for details
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
            fontFamily: 'Tajawal',
          ),
        ),
      );
    }).toList();
  }

  Widget _buildWithdrawalForm(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input
            Text(
              "withdrawal_amount".tr(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 10.h),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16.sp,
              ),
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
                suffixIcon: Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Text(
                    "currency_egy".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Method Selection Button
            Text(
              "withdrawal_method".tr(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 10.h),

            InkWell(
              onTap: () => _showMethodSelection(context, isDark),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedMethod != null &&
                        _selectedMethod!['image'].isNotEmpty)
                      Image.asset(
                        _selectedMethod!['image'],
                        width: 30.w,
                        height: 30.h,
                      ),

                    if (_selectedMethod != null) SizedBox(width: 12.w),

                    Text(
                      _selectedMethod != null
                          ? (_selectedMethod!['name'] as String).tr()
                          : "select_method".tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Dynamic Fields Animation
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _selectedMethod != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...(_selectedMethod!['fields'] as List).map((fieldId) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "field_$fieldId".tr(),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextFormField(
                                  controller: _controllers[fieldId],
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        "hint_$fieldId".tr() != "hint_$fieldId"
                                        ? "hint_$fieldId".tr()
                                        : "", // Use hint if exists
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            if (_selectedMethod != null) ...[
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: Text(
                    "submit_request".tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
