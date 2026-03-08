// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "servino-85dab",
      "private_key_id": "f9a6ab763d062e5f60c12b7390371f96e0c92c10",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCNV1XKes4OoxrJ\npFhSaOy+qYbHbVfOBDWfDEAdvMF23R/G13rG3Lk4OI3YCyLb9ZoYa5nYLbz/Y8kE\nbzfggxJ/mqYEHHgW1H5mMduZ5k3O4sP0my0oQ2Sknq8UmqsmtApYKuAAWgjiQ+SS\nz8BtPgvIelvz5wgTuKBgZ+TC97r4lYtQvchnIO9i07WS2IVcDqnUKJ3ucHfw6+Je\nbCNKAFIOtr83gukAbJNb6Vs9l93OGkNdoftHV6PQSPw0XPupJLu91UwAHmuFB1RY\nhIJBdsBAVQ7me/h2YDsvRbZIQdXpOjjBV9ADSFAXirJYOt9o1f1gXagDl/fyNiHE\nbgYVIigHAgMBAAECggEAAY9Z0lCLyUDOXGHJacPnsqkDzfKsYZCCRTt/tF26wQSm\n/94WyjJx3XptX4bZHWGcpqKGVLgJdHj3ytsekNkr2NTBRcqFHlG9jHUGPSGhnifJ\nkP/FGJ2FGNDbbNRoxZZRpKx48H+VbCofBL0Wyhv9lT5dL5+S4zfkpXu/H/9mXzT7\nXSmmAC6dUCqTpucJJeniehL6/MvWl3cjlSBmz5jSfk8/Wl+w1Kb5wvHkBEM34A/y\nOAIZt7X3ncP/itO0MZ2kcujfg+BSCwbanKD9HGER5Qll8URZAhsz4zQMMcyyruqQ\nwxiPRLnJwpOQAX4VG96zqSVa1dYDDxILsdtsfnKwhQKBgQC+8xHlHNVkK2YsHHZ9\nJjDDMQsxjGwe9V4dQZ7638ICXmQkkOEnGAWTqtRQ4NWTG3IYxTzKkyYB8r053oj/\nyj6e6HUqia05ItyMGBbhAPNCZFdVcGM+yK+LmkxkfwO6an/IfeAo2IgMRsV8L26B\n3YAMDBgj7yoQRVuP0YuKFxgANQKBgQC9fd0RGYxlf1AfJcH1Tc6wmGsxBhxsN0jy\nSg6VKchRuViAMvzvOUeSaPlYFm7HqGzWSMusv1blnG+TaKep1caUjh+OYeETODOM\nzIO08QEuxanKNtGf+7+9ewkgP92DfJ7s9sARThTgyUFLZWGh64tnv8Zm9Z6LQxPS\nbZyrMU3GywKBgHtt7eRWxg1RDGN5JpJxLFYQDrdBmOZOHz70Gwr5tpQHZd5JFHFL\n0tcINuPs4cGMnS0r2cbsZUYfHXgZxB7sIZxgkNQlWKa1RTD9pVReY+BHsjhVRKHh\n4a9w1u6jN8q5as4zp8FfblnZKXDDzD//6PRgoP4ha+RGoRAPGI7zrJz9AoGAJw3A\nuRx93hFOLw02G1uM5MKVHQZ4ZylBxIXU2ZNB8O31On7HuHoisR8nfKsq68VfoQ5h\nw9mvjCUgrc3c+FjR054zDMJJhA+KOFOSNYGST9R3OPDxZTqaeu/Xoqjm+4l8q7Pz\nQ93G2clAxsw/QgLsuVZCCshGg8cwV6c1qebAc98CgYEArDyeKIbEmzAYCLYP0iMC\nP2VrsBDPqwj6b0XM9vltSqWgLAPmtus6vP102C5RFXX4dWPdcvMdomW7O882ZDf0\n1sRfZUsTA7xbtvg8FGmM4E4PFbYKqUnzsHQajRrzCDipag0BIicwI4ylEpMlBXTc\nYQIrt3uRoncWq/X1dVlxnzE=\n-----END PRIVATE KEY-----\n",
      "client_email": "servino@servino-85dab.iam.gserviceaccount.com",
      "client_id": "106162137483060817793",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/servino%40servino-85dab.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client,
        );
    client.close();
    return credentials.accessToken.data;
  }

  static Future<void> sendNotification(
    String deviceToken,
    String title,
    String body,
  ) async {
    final String accessToken = await getAccessToken();
    String endpointFCM =
        'https://fcm.googleapis.com/v1/projects/servicesapp2024/messages:send';
    final Map<String, dynamic> message = {
      "message": {
        "token": deviceToken,
        "notification": {"title": title, "body": body},
        "data": {"route": "serviceScreen"},
      },
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFCM),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
    }
  }
}
