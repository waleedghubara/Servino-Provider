import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/wallet/data/models/wallet_transaction_model.dart';

class WalletRepository {
  final DioConsumer api;

  WalletRepository({required this.api});

  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await api.get('wallet/get_balance.php');
      if (response['status'] == 1) {
        return response['data'];
      }
      return {'balance': '0.00', 'currency': 'EGP'};
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WalletTransactionModel>> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await api.get(
        'wallet/get_transactions.php',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response['status'] == 1) {
        final List list = response['data'] ?? [];
        return list.map((e) => WalletTransactionModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String details,
  }) async {
    try {
      final response = await api.post(
        'wallet/withdraw.php',
        data: {'amount': amount, 'details': details},
      );
      if (response['status'] != 1) {
        throw Exception(response['message'] ?? 'Withdrawal failed');
      }
    } catch (e) {
      rethrow;
    }
  }
}
