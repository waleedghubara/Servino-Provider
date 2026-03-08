import 'dart:io';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/payment/models/payment_gateway_model.dart';
import 'package:servino_provider/features/payment/models/financial_reports_model.dart';
import 'package:servino_provider/features/payment/models/payment_params.dart';

class PaymentRepository {
  final DioConsumer api;

  PaymentRepository({required this.api});

  Future<List<PaymentGatewayModel>> getGateways() async {
    try {
      final response = await api.get('payment/get_gateways.php');

      if (response['status'] == 1 && response['data'] != null) {
        final List data = response['data'];
        return data.map((e) => PaymentGatewayModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> createTransaction({
    required int userId,
    required double amount,
    required int methodId,
    required String methodName,
    required String senderFrom,
    String? receiptImageInfo,
    String? planId,
    bool isSubscription = false,
    String? description,
    String? currency,
    double? originalAmount,
    int? discountPercentage,
    String? title,
    String? deviceInfo,
  }) async {
    try {
      final response = await api.post(
        'payment/create_transaction.php',
        data: {
          'user_id': userId,
          'amount': amount,
          'method_id': methodId,
          'method_name': methodName,
          'sender_from': senderFrom,
          'receipt_image': receiptImageInfo ?? '',
          'plan_id': planId ?? '',
          'is_subscription': isSubscription ? 1 : 0,
          'description': description ?? '',
          'currency': currency ?? '',
          'original_amount': originalAmount ?? 0,
          'discount_percentage': discountPercentage ?? 0,
          'title': title ?? '',
          'app_type': 'provider', // Explicitly identifying this app
          'device_info': deviceInfo ?? '',
        },
      );

      if (response['status'] == 1) {
        return response['transaction_id']?.toString();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiatePaypal({
    required int userId,
    required double amount,
    required PaymentParams params,
    required int methodId,
    required String methodName,
  }) async {
    try {
      final response = await api.post(
        'payment/paypal_init.php',
        data: {
          'user_id': userId,
          'amount': amount,
          'method_id': methodId,
          'method_name': methodName,
          'currency': params.currency,
          'plan_id': params.planId ?? '',
          'is_subscription': params.isSubscription ? 1 : 0,
          'title': params.title,
          'description': params.description,
          'app_type': 'provider', // Explicitly identifying this app
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> checkTransactionStatus(String transactionId) async {
    try {
      final response = await api.get(
        'payment/check_status.php',
        queryParameters: {'transaction_id': transactionId},
      );

      if (response['status'] == 1 && response['data'] != null) {
        return response['data']['transaction_status'] ?? 'pending';
      }
      return 'pending';
    } catch (e) {
      return 'pending'; // Default to pending on error to keep polling
    }
  }

  Future<String?> uploadReceipt(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await api.post(
        'upload/file.php',
        data: formData,
        isFromData: false,
      );

      if (response['status'] == 1) {
        return response['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<FinancialReportModel?> getFinancialReports({
    int? month,
    int? year,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await api.get(
        'wallet/get_reports.php',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response['status'] == 1 && response['data'] != null) {
        return FinancialReportModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
