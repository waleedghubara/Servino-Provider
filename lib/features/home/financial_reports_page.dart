// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/features/payment/models/financial_reports_model.dart';
import 'package:servino_provider/features/home/widgets/financial_dashboard.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/home/services/financial_pdf_service.dart';

import 'package:servino_provider/features/payment/data/repo/payment_repo.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';

class FinancialReportsPage extends StatefulWidget {
  final FinancialReportModel initialReports;

  const FinancialReportsPage({super.key, required this.initialReports});

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage> {
  late FinancialReportModel currentReports;
  int? selectedMonth;
  int? selectedYear;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentReports = widget.initialReports;
  }

  Future<void> _fetchFilteredReports() async {
    setState(() => isLoading = true);
    try {
      final repo = PaymentRepository(api: DioConsumer(dio: Dio()));
      final reports = await repo.getFinancialReports(
        month: selectedMonth,
        year: selectedYear,
      );
      if (reports != null && mounted) {
        setState(() => currentReports = reports);
      }
    } catch (e) {
      // Handle error natively or silently
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMonthYearPicker() {
    int tempMonth = selectedMonth ?? DateTime.now().month;
    int tempYear = selectedYear ?? DateTime.now().year;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.date_range_rounded,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'select_period'.tr(),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCustomDropdown<int>(
                          label: 'month'.tr(),
                          value: tempMonth,
                          items: List.generate(12, (index) => index + 1),
                          itemLabel: (val) => DateFormat(
                            'MMMM',
                            context.locale.languageCode,
                          ).format(DateTime(2020, val)),
                          isDark: isDark,
                          onChanged: (val) =>
                              setStateSheet(() => tempMonth = val!),
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: _buildCustomDropdown<int>(
                          label: 'year'.tr(),
                          value: tempYear,
                          items: List.generate(
                            5,
                            (index) => DateTime.now().year - index + 1,
                          ),
                          itemLabel: (val) => val.toString(),
                          isDark: isDark,
                          onChanged: (val) =>
                              setStateSheet(() => tempYear = val!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedMonth = null;
                              selectedYear = null;
                            });
                            Navigator.pop(context);
                            _fetchFilteredReports();
                          },
                          child: Text(
                            'clear'.tr(),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 5,
                            shadowColor: AppColors.primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedMonth = tempMonth;
                              selectedYear = tempYear;
                            });
                            Navigator.pop(context);
                            _fetchFilteredReports();
                          },
                          child: Text(
                            'apply'.tr(),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required bool isDark,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.blue.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
              ),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "financial_reports".tr(),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            onPressed: () => FinancialPdfService.previewAndSaveReport(
              reports: currentReports,
              isArabic: context.locale.languageCode == 'ar',
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
            ),
            icon: Icon(
              Icons.file_download_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: "Download PDF",
          ),
          IconButton(
            onPressed: () => FinancialPdfService.generateAndShareReport(
              reports: currentReports,
              isArabic: context.locale.languageCode == 'ar',
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
            ),
            icon: Icon(
              Icons.share_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: "Share PDF",
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    InkWell(
                      onTap: _showMonthYearPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark
                              : const Color(0xFFF8F9FE),
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.blue.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark.withOpacity(0.1)
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.filter_list_rounded,
                                color: isDark
                                    ? AppColors.primary
                                    : AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              selectedMonth != null && selectedYear != null
                                  ? "${DateFormat('MMM', context.locale.languageCode).format(DateTime(2020, selectedMonth!))} $selectedYear"
                                  : "filter_by_date".tr(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    _DetailSummaryCards(
                      reports: currentReports,
                      isDark: isDark,
                    ),
                    SizedBox(height: 30.h),
                    _buildSectionTitle("weekly_performance".tr(), isDark),
                    SFinancialChart(
                      data: currentReports.dailyEarnings,
                      isDark: isDark,
                    ),
                    SizedBox(height: 30.h),
                    _buildSectionTitle("monthly_performance".tr(), isDark),
                    SFinancialChart(
                      data: currentReports.monthlyEarnings,
                      isDark: isDark,
                    ),
                  ],
                  SizedBox(height: 30.h),
                  // Additional Placeholder for Transaction list or more metrics
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h, left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}

class _DetailSummaryCards extends StatelessWidget {
  final FinancialReportModel reports;
  final bool isDark;

  const _DetailSummaryCards({required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      children: [
        _buildDetailCard(
          "total_earned".tr(),
          reports.totalEarned,
          reports.currency,
          AppColors.success,
          Icons.trending_up_rounded,
        ),
        _buildDetailCard(
          "total_withdrawn".tr(),
          reports.totalWithdrawn,
          reports.currency,
          AppColors.error,
          Icons.trending_down_rounded,
        ),
        _buildDetailCard(
          "current_balance".tr(),
          reports.balance,
          reports.currency,
          AppColors.primary,
          Icons.account_balance_rounded,
        ),
        _buildDetailCard(
          "net_profit".tr(),
          reports.totalEarned - reports.totalWithdrawn,
          reports.currency,
          Colors.orange,
          Icons.pie_chart_rounded,
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    double amount,
    String currency,
    Color color,
    IconData icon,
  ) {
    return FadeInUp(
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            FittedBox(
              child: Text(
                "${amount.toStringAsFixed(2)} $currency",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
