import 'package:servino_provider/core/api/api_consumer.dart';
import 'package:servino_provider/core/api/end_point.dart';
import 'package:servino_provider/core/errors/exception.dart';

class BookingRepository {
  final ApiConsumer api;

  BookingRepository({required this.api});

  Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      final response = await api.get(
        'bookings/read_by_provider.php',
      ); // Clean endpoint later
      if (response['status'] == 1) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> updateStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      final response = await api.post(
        EndPoint.updateBookingStatus,
        data: {'booking_id': bookingId, 'status': status},
      );
      if (response['status'] == 0) {
        throw response['message'];
      }
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendReminder(int bookingId) async {
    try {
      final response = await api.post(
        EndPoint.sendReminder,
        data: {'booking_id': bookingId},
      );
      if (response['status'] == 0) {
        throw response['message'];
      }
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    } catch (e) {
      throw e.toString();
    }
  }
}
