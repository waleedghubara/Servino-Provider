import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:servino_provider/features/payment/models/financial_reports_model.dart';
import 'package:servino_provider/core/theme/assets.dart';

class FinancialPdfService {
  static Future<void> generateAndShareReport({
    required FinancialReportModel reports,
    required bool isArabic,
    int? selectedMonth,
    int? selectedYear,
  }) async {
    final pdf = await _generateDocument(
      reports,
      isArabic,
      selectedMonth,
      selectedYear,
    );

    // Share/Print the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Financial_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> previewAndSaveReport({
    required FinancialReportModel reports,
    required bool isArabic,
    int? selectedMonth,
    int? selectedYear,
  }) async {
    final pdf = await _generateDocument(
      reports,
      isArabic,
      selectedMonth,
      selectedYear,
    );

    // Opening Interactive Preview (Allows Save, Print, Share)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Financial_Report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static Future<pw.Document> _generateDocument(
    FinancialReportModel reports,
    bool isArabic,
    int? selectedMonth,
    int? selectedYear,
  ) async {
    final pdf = pw.Document();

    // Load fonts for Arabic support
    final fontData = await rootBundle.load("assets/fonts/Tajawal-Medium.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load(Assets.logoApp);
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Fallback if logo fails
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
          italic: ttf,
          boldItalic: ttf,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(logoImage, isArabic, selectedMonth, selectedYear),
            pw.SizedBox(height: 20),
            _buildSummarySection(reports, isArabic),
            pw.SizedBox(height: 30),
            _buildWeeklySection(reports, isArabic),
            pw.SizedBox(height: 30),
            _buildMonthlySection(reports, isArabic),
            pw.SizedBox(height: 40),
            _buildFooter(isArabic),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    bool isArabic,
    int? selectedMonth,
    int? selectedYear,
  ) {
    String reportTitle = isArabic
        ? "تقرير الأداء المالي"
        : "Financial Performance Report";
    if (selectedMonth != null && selectedYear != null) {
      reportTitle += isArabic
          ? " (شهر $selectedMonth / $selectedYear)"
          : " ($selectedMonth/$selectedYear)";
    }

    return pw.Directionality(
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                reportTitle,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                "${isArabic ? 'تاريخ الاستخراج:' : 'Exported On:'} ${easy.DateFormat('yyyy-MM-dd').format(DateTime.now())}",
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          if (logo != null)
            pw.Container(width: 60, height: 60, child: pw.Image(logo)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    FinancialReportModel reports,
    bool isArabic,
  ) {
    return pw.Directionality(
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? "ملخص الحساب" : "Account Summary",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                isArabic ? "إجمالي الأرباح" : "Total Earned",
                "${reports.totalEarned.toStringAsFixed(2)} ${reports.currency}",
                PdfColors.green900,
                isArabic,
              ),
              _buildSummaryCard(
                isArabic ? "إجمالي المسحوبات" : "Total Withdrawn",
                "${reports.totalWithdrawn.toStringAsFixed(2)} ${reports.currency}",
                PdfColors.red900,
                isArabic,
              ),
              _buildSummaryCard(
                isArabic ? "الرصيد الحالي" : "Current Balance",
                "${reports.balance.toStringAsFixed(2)} ${reports.currency}",
                PdfColors.blue900,
                isArabic,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(
    String title,
    String value,
    PdfColor color,
    bool isArabic,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWeeklySection(
    FinancialReportModel reports,
    bool isArabic,
  ) {
    return pw.Directionality(
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic
                ? "الأداء الأسبوعي (آخر 7 أيام)"
                : "Weekly Performance (Last 7 Days)",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.center,
            data: <List<String>>[
              <String>[
                isArabic ? 'التاريخ' : 'Date',
                isArabic ? 'اليوم' : 'Day',
                isArabic ? 'المبلغ' : 'Amount',
              ],
              ...reports.dailyEarnings.map(
                (e) => [
                  e.date ?? '',
                  e.translatedLabel(isArabic),
                  "${e.amount.toStringAsFixed(2)} ${reports.currency}",
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMonthlySection(
    FinancialReportModel reports,
    bool isArabic,
  ) {
    return pw.Directionality(
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic
                ? "الأداء الشهري (آخر 6 أشهر)"
                : "Monthly Performance (Last 6 Months)",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellAlignment: pw.Alignment.center,
            data: <List<String>>[
              <String>[
                isArabic ? 'الشهر' : 'Month',
                isArabic ? 'المبلغ' : 'Amount',
              ],
              ...reports.monthlyEarnings.map(
                (e) => [
                  e.translatedLabel(isArabic),
                  "${e.amount.toStringAsFixed(2)} ${reports.currency}",
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(bool isArabic) {
    return pw.Directionality(
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Column(
        children: [
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                isArabic
                    ? "صادر من تطبيق سيرفينو - مزود الخدمة"
                    : "Issued by Servino Provider App",
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
