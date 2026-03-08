// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/payment/data/repo/payment_repo.dart';
import 'package:servino_provider/features/payment/models/payment_gateway_model.dart';
import 'package:servino_provider/features/payment/models/payment_params.dart';
import 'package:servino_provider/features/payment/pages/paypal_checkout_page.dart';

class PaymentMethodSelectionPage extends StatefulWidget {
  final PaymentParams params;

  const PaymentMethodSelectionPage({super.key, required this.params});

  @override
  State<PaymentMethodSelectionPage> createState() =>
      _PaymentMethodSelectionPageState();
}

class _PaymentMethodSelectionPageState extends State<PaymentMethodSelectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PaymentRepository _repository;

  List<PaymentGatewayModel> _gateways = [];
  bool _isLoading = true;
  String _error = '';
  PaymentGatewayModel? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repository = PaymentRepository(api: DioConsumer(dio: Dio()));
    _fetchGateways();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchGateways() async {
    try {
      final gateways = await _repository.getGateways();
      setState(() {
        _gateways = gateways;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load methods: $e';
        _isLoading = false;
      });
    }
  }

  void _onContinue() {
    if (_selectedMethod == null) return;

    if (_selectedMethod!.keyword == 'visa') {
      AppRouter.navigateTo(
        context,
        Routes.paymentDetails,
        arguments: widget.params,
      );
    } else if (_selectedMethod!.keyword == 'google') {
      AppRouter.navigateTo(
        context,
        Routes.paymentSuccess,
        arguments: widget.params,
      );
    } else if (_selectedMethod!.keyword == 'paypal') {
      AppRouter.navigateTo(
        context,
        Routes.paypalCheckout,
        arguments: PaypalCheckoutPageParams(
          params: widget.params,
          gateway: _selectedMethod!,
        ),
      );
    } else {
      // Manual Instructions (Vodafone, InstaPay, Binance)
      // Passed 'method' as PaymentGatewayModel
      AppRouter.navigateTo(
        context,
        Routes.paymentInstruction,
        arguments: {'params': widget.params, 'method': _selectedMethod},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter gateways by location
    final egyptMethods = _gateways
        .where((m) => m.location.toLowerCase() == 'egypt')
        .toList();
    final globalMethods = _gateways
        .where((m) => m.location.toLowerCase() != 'egypt')
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'payment_select_method_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),

                // Invoice / Bill Summary
                _buildInvoiceCard(isDark),

                SizedBox(height: 20.h),

                // Custom Tab Bar Container
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary2 : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: isDark ? Colors.white : Colors.black,
                    unselectedLabelColor: isDark ? Colors.white : Colors.black,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                    ),
                    tabs: [
                      Tab(text: 'payment_location_egypt'.tr()),
                      Tab(text: 'payment_location_global'.tr()),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error.isNotEmpty
                      ? Center(
                          child: Text(
                            _error,
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Egypt Tab
                            _buildMethodsList(egyptMethods),
                            // Global Tab
                            _buildMethodsList(globalMethods),
                          ],
                        ),
                ),

                // Continue Button
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _selectedMethod != null ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: _selectedMethod != null ? 8 : 0,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                      child: Text(
                        'continue_payment'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
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
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'subscription_plans'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                widget.params.title.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'booking_total_amount'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${double.tryParse(widget.params.amount.toString())?.toStringAsFixed(2) ?? widget.params.amount} ${widget.params.currency}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (widget.params.description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                widget.params.description.tr(),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodsList(List<PaymentGatewayModel> methods) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (methods.isEmpty) {
      return Center(
        child: Text(
          "No payment methods available",
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      itemCount: methods.length,
      separatorBuilder: (_, _) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final method = methods[index];
        final isSelected = _selectedMethod?.id == method.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMethod = method;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: method.getColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      method.getFullImageUrl(),
                      fit: BoxFit.cover,
                      width: 70.w,
                      height: 70.h,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.payment,
                        size: 40,
                        color: method.getColor(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.getName(context),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        method.getDescription(context),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
