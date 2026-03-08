class EndPoint {
  static const String markRead = 'notifications/mark_read.php';
  static const String baseUrl =
      'https://walidghubara.online/backend-servino/api/';
  static const String imageBaseUrl =
      'https://walidghubara.online/backend-servino/';
  static String register = 'auth/register.php';
  static String verifyOtp = 'auth/verify_otp.php';
  static String resendOtp = 'auth/resend_otp.php';
  static String forgotPassword = 'auth/forgot_password.php';
  static String resetPassword = 'auth/reset_password.php';
  static String login = 'auth/login.php';
  static String getCategories = 'categories/read.php';
  static String getBookings = 'bookings/read_by_provider.php';
  static String updateBookingStatus = 'bookings/update_status.php';
  static String sendReminder = 'bookings/send_reminder.php';
  static String getProfile = 'auth/get_profile.php';
  static String updateProfile = 'auth/update_profile.php';
  static String updateFcmToken = 'auth/update_fcm_token.php';
  static String getNotifications = 'notifications/get_notifications.php';
  static String updateStatus = 'chat/update_status.php';
  static String getUserStatus = 'chat/get_status.php';
  static String getReports = 'wallet/get_reports.php';
  static String securityLog = 'security/log.php';
  static String validateIntegrity = 'security/validate_integrity.php';
  static String validatePayment = 'payments/validate_payment.php';
}

class ApiKey {
  static String id = 'id';
  static String token = 'token';
  static String message = 'message';
  static String status = 'status';
  static String errormessage = 'ErrorMessage';
  static String name = 'name';
  static String storeName = 'storeName';
  static String tradeType = 'tradeType';
  static String city = 'city';
  static String address = 'address';
  static String email = 'email';
  static String password = 'password';
  static String confirmPassword = 'confirmPassword';
  static String phone = 'phone';
  static String profileImage = 'profileImage';
  static String imageDocument = 'imageDocument';
  static String verifyotpphone = 'verifyotpphone';
  static String verifyotpemail = 'otp_code';
  static String oldPassword = 'Old_password';
  static String newPassword = 'New_password';
  static String count = 'count';
  static String nameAddFayah = 'nameaddFayah';
  static String vehicle = 'vehicle';
  static String plate = 'plate';
}
