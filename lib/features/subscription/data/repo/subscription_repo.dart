import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/subscription/models/plan_model.dart';

class SubscriptionRepository {
  final DioConsumer api;

  SubscriptionRepository({required this.api});

  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await api.get('plans/get_plans.php');
      if (response['status'] == 1 && response['data'] != null) {
        return List<Map<String, dynamic>>.from(
          response['data'],
        ).map((json) => PlanModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
