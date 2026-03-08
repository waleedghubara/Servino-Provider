class WalletTransactionModel {
  final int id;
  final double amount;
  final String type; // credit, debit
  final String description;
  final String status; // completed, pending, failed
  final String statusTranslated;
  final String typeTranslated;
  final String date;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.status,
    required this.statusTranslated,
    required this.typeTranslated,
    required this.date,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      statusTranslated: json['status_translated'] ?? json['status'] ?? '',
      typeTranslated: json['type_translated'] ?? json['type'] ?? '',
      date: json['created_at'] ?? '',
    );
  }
}
