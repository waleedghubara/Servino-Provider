// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/features/payment/models/financial_reports_model.dart';
import 'package:servino_provider/features/home/financial_reports_page.dart';
import 'dart:ui' as ui;

class FinancialDashboard extends StatelessWidget {
  final FinancialReportModel reports;
  final bool isDark;

  const FinancialDashboard({
    super.key,
    required this.reports,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "financial_overview".tr(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Tajawal',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FinancialReportsPage(initialReports: reports),
                    ),
                  );
                },
                child: Text(
                  "view_details".tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
        ),
        SSummaryCards(reports: reports, isDark: isDark),
        SizedBox(height: 20.h),
        SFinancialChart(data: reports.dailyEarnings, isDark: isDark),
      ],
    );
  }
}

class SSummaryCards extends StatelessWidget {
  final FinancialReportModel reports;
  final bool isDark;

  const SSummaryCards({super.key, required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCard(
            title: "total_earned".tr(),
            amount: reports.totalEarned,
            currency: reports.currency,
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
          _buildCard(
            title: "total_withdrawn".tr(),
            amount: reports.totalWithdrawn,
            currency: reports.currency,
            icon: Icons.outbond_rounded,
            color: AppColors.error,
          ),
          _buildCard(
            title: "current_balance".tr(),
            amount: reports.balance,
            currency: reports.currency,
            icon: Icons.payments_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required double amount,
    required String currency,
    required IconData icon,
    required Color color,
  }) {
    return FadeInRight(
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 12.w, bottom: 10.h, left: 4.w),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),

          border: Border.all(
            color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 4.h),
            FittedBox(
              child: Text(
                "${amount.toStringAsFixed(2)} $currency",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'XBFont_ENG',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SFinancialChart extends StatelessWidget {
  final List<ChartData> data;
  final bool isDark;

  const SFinancialChart({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: Container(
        height: 250.h,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.surfaceDark, const Color(0xFF2C3E50)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF0F4FF)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.blue.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "weekly_earnings".tr(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: CustomPaint(
                painter: _BarChartPainter(data: data, isDark: isDark),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  final bool isDark;

  _BarChartPainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;

    final maxAmount = data
        .map((e) => e.amount)
        .fold(0.0, (a, b) => a > b ? a : b);
    final effectiveMax = maxAmount == 0 ? 100.0 : maxAmount * 1.2;

    final barWidth = size.width / (data.length * 2);
    final spacing = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i].amount / effectiveMax) * size.height;
      final x = (i * spacing) + (spacing - barWidth) / 2;
      final y = size.height - barHeight;

      // Draw shadow/glow
      final shadowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          Radius.circular(6.r),
        ),
        shadowPaint,
      );

      // Draw bar
      paint.shader = ui.Gradient.linear(Offset(x, y), Offset(x, size.height), [
        AppColors.primaryLight,
        AppColors.primary,
      ]);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          Radius.circular(6.r),
        ),
        paint,
      );

      // Draw Label
      final isArabic = ui.window.locale.languageCode == 'ar';
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: data[i].translatedLabel(isArabic),
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 10.sp,
            fontFamily: 'Tajawal',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, size.height + 8.h),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
