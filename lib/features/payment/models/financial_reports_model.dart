class FinancialReportModel {
  final double balance;
  final String currency;
  final double totalEarned;
  final double totalWithdrawn;
  final List<ChartData> dailyEarnings;
  final List<ChartData> monthlyEarnings;

  FinancialReportModel({
    required this.balance,
    required this.currency,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.dailyEarnings,
    required this.monthlyEarnings,
  });

  factory FinancialReportModel.fromJson(Map<String, dynamic> json) {
    return FinancialReportModel(
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] ?? '',
      totalEarned: (json['total_earned'] as num).toDouble(),
      totalWithdrawn: (json['total_withdrawn'] as num).toDouble(),
      dailyEarnings: (json['daily_earnings'] as List)
          .map((e) => ChartData.fromJson(e))
          .toList(),
      monthlyEarnings: (json['monthly_earnings'] as List)
          .map((e) => ChartData.fromJson(e))
          .toList(),
    );
  }
}

class ChartData {
  final String label;
  final double amount;
  final String? date;

  ChartData({required this.label, required this.amount, this.date});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] ?? json['month'],
    );
  }

  String translatedLabel(bool isArabic) {
    if (!isArabic) return label;

    const dayMap = {
      'Mon': 'الأثنين',
      'Tue': 'الثلاثاء',
      'Wed': 'الأربعاء',
      'Thu': 'الخميس',
      'Fri': 'الجمعة',
      'Sat': 'السبت',
      'Sun': 'الأحد',
    };

    const monthMap = {
      'Jan': 'يناير',
      'Feb': 'فبراير',
      'Mar': 'مارس',
      'Apr': 'أبريل',
      'May': 'مايو',
      'Jun': 'يونيو',
      'Jul': 'يوليو',
      'Aug': 'أغسطس',
      'Sep': 'سبتمبر',
      'Oct': 'أكتوبر',
      'Nov': 'نوفمبر',
      'Dec': 'ديسمبر',
    };

    return dayMap[label] ?? monthMap[label] ?? label;
  }
}
