// ignore_for_file: avoid_print

import 'package:servino_provider/core/cache/cache_helper.dart';
import 'package:servino_provider/core/api/end_point.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';

import 'package:easy_localization/easy_localization.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // تحديد نوع المحتوى فقط إذا لم تكن FormData
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    // Add Language Header (requires context, using navigatorKey)
    final context = navigatorKey.currentContext;
    if (context != null) {
      options.headers['lang'] = context.locale.languageCode;
    } else {
      options.headers['lang'] = 'en';
    }

    final token = await SecureCacheHelper().getData(key: ApiKey.token);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      // print('✅ Token Added: FOODAPI $token');
    } else {
      // print('⚠️ No token found in secure storage');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 0. Handle Banned Users (403)
    if (err.response?.statusCode == 403 &&
        err.response?.data is Map &&
        err.response?.data['is_banned'] == true) {
      // print('🚫 403 Banned - Redirecting to Banned Page');

      // Clear Token globally
      await SecureCacheHelper().removeData(key: ApiKey.token);

      // Navigate to Banned Screen
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.banned,
        (route) => false,
      );

      return super.onError(err, handler);
    }
    // 1. Handle Unauthorized (401)
    if (err.response?.statusCode == 401) {
      // print('⚠️ 401 Unauthorized - Logging out');

      // Clear Token
      await SecureCacheHelper().removeData(key: ApiKey.token);

      // Navigate to Login
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.login,
        (route) => false,
      );
    }

    // 2. Handle Server Errors (500+) or Connection Issues
    final isServerError =
        err.response?.statusCode != null && err.response!.statusCode! >= 500;

    final isConnectionError =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isServerError || isConnectionError) {
      // print('🔴 Server Error or Connection Failure Detected.');

      // navigatorKey.currentState?.pushNamedAndRemoveUntil(
      //   Routes.serverError,
      //   (route) => false,
      // );
    }

    super.onError(err, handler);
  }
}
