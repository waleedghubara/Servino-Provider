class PaymentParams {
  final String title;
  final double amount;
  final String currency;
  final String description;
  final bool isSubscription;
  final String? planId; // For subscription
  final String? providerId; // For provider payment

  PaymentParams({
    required this.title,
    required this.amount,
    required this.currency,
    required this.description,
    this.isSubscription = false,
    this.planId,
    this.providerId,
    this.originalAmount,
    this.discountPercentage,
  });

  final double? originalAmount;
  final int? discountPercentage;
}
