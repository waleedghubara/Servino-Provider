import 'package:servino_provider/core/api/api_consumer.dart';
import 'package:servino_provider/core/api/end_point.dart';
import 'package:servino_provider/core/errors/exception.dart';
import 'package:servino_provider/core/model/category_model.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/cache/cache_helper.dart';

class AuthRepository {
  final ApiConsumer api;

  AuthRepository({required this.api});

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await api.get(EndPoint.getCategories);
      if (response['status'] == 1 && response['data'] != null) {
        return (response['data'] as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
      return [];
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage; // Or handle error appropriately
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String dob,
    required String gender,
    required String categoryId,
    required String serviceId,
    required String experienceYears,
    required String description,
    required String price,
    required String currency,
    required String location,
    required String profileImagePath,
    required String idImagePath,
    String? certificateImagePath,
  }) async {
    try {
      final formData = {
        ApiKey.name: name,
        ApiKey.email: email,
        ApiKey.phone: phone,
        ApiKey.password: password,
        'dob': dob,
        'gender': gender,
        'category': categoryId,
        'service': serviceId,
        'experience_years': experienceYears,
        'description': description,
        'price': price,
        'currency': currency,
        'location': location,
        ApiKey.profileImage: await MultipartFile.fromFile(profileImagePath),
        'id_image': await MultipartFile.fromFile(idImagePath),
      };

      if (certificateImagePath != null) {
        formData['certificate_image'] = await MultipartFile.fromFile(
          certificateImagePath,
        );
      }

      await api.post(EndPoint.register, data: formData, isFromData: true);
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      await api.post(
        EndPoint.verifyOtp,
        data: {'email': email, 'otp_code': otpCode},
      );
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await api.post(EndPoint.resendOtp, data: {'email': email});
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    }
  }

  final _cacheHelper = SecureCacheHelper();

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await api.post(
        EndPoint.login,
        data: {'email': email, 'password': password},
      );

      if (response['status'] == 1) {
        // Save Token
        if (response['token'] != null) {
          await _cacheHelper.saveData(
            key: ApiKey.token,
            value: response['token'],
          );
        }
        // Return User Data
        return response['data'];
      } else {
        throw response['message'];
      }
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String?> getToken() async {
    return await _cacheHelper.getData(key: ApiKey.token);
  }

  Future<void> logout() async {
    await _cacheHelper.removeData(key: ApiKey.token);
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await api.post(
        EndPoint.forgotPassword,
        data: {'email': email},
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

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await api.post(
        EndPoint.resetPassword,
        data: {
          'email': email,
          'otp_code': otpCode,
          'new_password': newPassword,
        },
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

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await api.get(EndPoint.getProfile);
      if (response['status'] == 1) {
        return response['data'];
      } else {
        throw response['message'] ?? 'Failed to get profile';
      }
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> updateProfile({
    required String phone,
    required double price,
    required String description,
    required String location,
    required String currency,
  }) async {
    try {
      final response = await api.post(
        EndPoint.updateProfile,
        data: {
          'phone': phone,
          'price': price,
          'description': description,
          'location': location,
          'currency': currency,
        },
      );
      if (response['status'] == 0) {
        throw response['message'] ?? 'Failed to update profile';
      }
    } on ServerException catch (e) {
      throw e.errorModel.errorMessage;
    } catch (e) {
      throw e.toString();
    }
  }
}
