import 'package:servino_provider/core/api/end_point.dart';

class ErrorModel {
  ErrorModel({required this.status, required this.errorMessage});

  factory ErrorModel.fromJson(Map<String, dynamic> jsonData) {
    return ErrorModel(
      status: jsonData[ApiKey.status] is int ? jsonData[ApiKey.status] : 0,
      errorMessage:
          jsonData[ApiKey.errormessage] ??
          jsonData[ApiKey.message] ??
          jsonData['error'] ?? // دعم الرسالة البديلة
          'No error message',
    );
  }
  final int status;
  final String errorMessage;
}
