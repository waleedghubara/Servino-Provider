import 'package:servino_provider/core/api/end_point.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;
  // Profile Details
  final String? phone;
  final String? dob;
  final String? gender;
  final String? description;
  final String? price;
  final String? currency;
  final String? location;
  final String? idImage;
  final String? certificateImage;

  // Work Info
  final String? categoryId;
  final String? serviceId;

  // Subscription Fields
  final int? currentPlanId;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final bool isSubscribed;
  final bool isApproved; // For verification badge
  final double? balance; // Wallet Balance for Home Page
  // Backend Calculated Subscription
  final int daysRemaining;
  final int totalDays;
  // Activity Stats
  final int totalRequests;
  final int profileCompletion;
  final int reportsCount;
  final int profileViews;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.phone,
    this.dob,
    this.gender,
    this.description,
    this.price,
    this.currency,
    this.location,
    this.idImage,
    this.certificateImage,
    this.categoryId,
    this.serviceId,
    this.currentPlanId,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.isSubscribed = false,
    this.isApproved = false,
    this.balance,
    this.daysRemaining = 0,
    this.totalDays = 30,
    this.totalRequests = 0,
    this.profileCompletion = 0,
    this.reportsCount = 0,
    this.profileViews = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString().replaceAll(' ', 'T'));
    }

    return UserModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      profileImage: json['profile_image'],
      phone: json['phone'],
      dob: json['dob'],
      gender: json['gender'],
      description: json['description'],
      price: json['price'],
      currency: json['currency'],
      location: json['location'],
      idImage: json['id_image'],
      certificateImage: json['certificate_image'],
      categoryId: json['category_id']?.toString(), // Ensure string
      serviceId: json['service_id']?.toString(), // Ensure string
      currentPlanId: json['current_plan_id'] != null
          ? int.tryParse(json['current_plan_id'].toString())
          : null,
      subscriptionStart: parseDate(json['subscription_start']),
      subscriptionEnd: parseDate(json['subscription_end']),
      isSubscribed: json['is_subscribed'] == 1 || json['is_subscribed'] == true,
      isApproved: json['is_approved'] == 1 || json['is_approved'] == true,
      balance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString())
          : 0.0,
      totalRequests: json['total_requests'] != null
          ? int.tryParse(json['total_requests'].toString()) ?? 0
          : 0,
      profileCompletion: json['profile_completion'] != null
          ? int.tryParse(json['profile_completion'].toString()) ?? 0
          : 0,
      reportsCount: json['total_reports'] != null
          ? int.tryParse(json['total_reports'].toString()) ?? 0
          : 0,
      profileViews: json['profile_views'] != null
          ? int.tryParse(json['profile_views'].toString()) ?? 0
          : 0,
      daysRemaining: json['days_remaining'] != null
          ? int.tryParse(json['days_remaining'].toString()) ?? 0
          : 0,
      totalDays: json['total_subscription_days'] != null
          ? int.tryParse(json['total_subscription_days'].toString()) ?? 30
          : 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profile_image': profileImage,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'description': description,
      'price': price,
      'currency': currency,
      'location': location,
      'id_image': idImage,
      'certificate_image': certificateImage,
      'category_id': categoryId,
      'service_id': serviceId,
      'current_plan_id': currentPlanId,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_end': subscriptionEnd?.toIso8601String(),
      'is_subscribed': isSubscribed,
      'is_approved': isApproved,
      'wallet_balance': balance,
      'total_requests': totalRequests,
      'profile_completion': profileCompletion,
      'total_reports': reportsCount,
      'profile_views': profileViews,
    };
  }

  // No local getters for daysRemaining or totalDays anymore as they come from backend

  String? get fullProfileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) return null;
    if (profileImage!.startsWith('http')) return profileImage;
    return '${EndPoint.imageBaseUrl}$profileImage';
  }
}
