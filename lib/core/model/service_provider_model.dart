import 'package:servino_provider/core/model/review_model.dart';

class ServiceProviderModel {
  final String id;
  final String name;
  final String categoryId;
  final String subCategory; // Translation Key
  final double rating;
  final int reviewCount;
  final String location; // Translation Key
  final String imageUrl;
  final double priceStart;
  final bool isAvailable; // Restored field
  final String about; // Translation Key
  final bool isVerified;
  final int yearsOfExperience;
  final bool isOnline;
  final List<ReviewModel> reviews;

  const ServiceProviderModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.subCategory,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.imageUrl,
    required this.priceStart,
    required this.isAvailable,
    required this.about,
    required this.isVerified,
    required this.yearsOfExperience,
    required this.isOnline,
    this.reviews = const [],
  });

  static List<ReviewModel> mockReviews = [
    ReviewModel(
      id: 'r1',
      userName: 'Mohamed Ahmed',
      userImage: 'https://randomuser.me/api/portraits/men/32.jpg',
      rating: 5.0,
      comment: 'Excellent service! The doctor was very professional and kind.',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewModel(
      id: 'r2',
      userName: 'Sara Ali',
      userImage: 'https://randomuser.me/api/portraits/women/44.jpg',
      rating: 4.5,
      comment: 'Great experience, but the waiting time was a bit long.',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReviewModel(
      id: 'r3',
      userName: 'Omar Hassan',
      userImage: 'https://randomuser.me/api/portraits/men/65.jpg',
      rating: 5.0,
      comment: 'Highly recommended! Explained everything clearly.',
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static List<ServiceProviderModel> mockProviders = [
    ServiceProviderModel(
      id: 'd1',
      name: 'Dr. Sarah Johnson',
      categoryId: '1',
      subCategory: 'sub_gp',
      rating: 4.9,
      reviewCount: 120,
      location: 'loc_cairo',
      imageUrl:
          'https://images.pexels.com/photos/1170976/pexels-photo-1170976.jpeg',
      priceStart: 300,
      isAvailable: true,
      about: 'service_provider_about_1',
      isVerified: true,
      yearsOfExperience: 10,
      isOnline: true,
      reviews: mockReviews,
    ),

    ServiceProviderModel(
      id: 'd2',
      name: 'Dr. Ahmed Ali',
      categoryId: '1',
      subCategory: 'sub_dentist',
      rating: 4.7,
      reviewCount: 85,
      location: 'loc_giza',
      imageUrl:
          'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg',
      priceStart: 450,
      isAvailable: true,
      about: 'service_provider_about_2',
      isVerified: true,
      yearsOfExperience: 8,
      isOnline: false,
      reviews: [
        ReviewModel(
          id: 'r2',
          userName: 'Sara Ali',
          userImage: 'https://randomuser.me/api/portraits/women/44.jpg',
          rating: 4.5,
          comment: 'Great experience, but the waiting time was a bit long.',
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ReviewModel(
          id: 'r3',
          userName: 'Omar Hassan',
          userImage: 'https://randomuser.me/api/portraits/men/65.jpg',
          rating: 5.0,
          comment: 'Highly recommended! Explained everything clearly.',
          date: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
    ),

    const ServiceProviderModel(
      id: 'd3',
      name: 'Dr. Michael Brown',
      categoryId: '1',
      subCategory: 'sub_cardiologist',
      rating: 4.8,
      reviewCount: 140,
      location: 'loc_new_cairo',
      imageUrl:
          'https://images.pexels.com/photos/615326/pexels-photo-615326.jpeg',
      priceStart: 600,
      isAvailable: true,
      about: 'service_provider_about_3',
      isVerified: false,
      yearsOfExperience: 15,
      isOnline: true,
    ),

    const ServiceProviderModel(
      id: 'd4',
      name: 'Dr. Lina Hassan',
      categoryId: '1',
      subCategory: 'sub_dermatologist',
      rating: 4.6,
      reviewCount: 70,
      location: 'loc_maadi',
      imageUrl:
          'https://images.pexels.com/photos/3845766/pexels-photo-3845766.jpeg',
      priceStart: 350,
      isAvailable: true,
      about: 'service_provider_about_4',
      isVerified: true,
      yearsOfExperience: 5,
      isOnline: false,
    ),

    const ServiceProviderModel(
      id: 'd5',
      name: 'Dr. Omar Khaled',
      categoryId: '1',
      subCategory: 'sub_pediatrician',
      rating: 4.9,
      reviewCount: 160,
      location: 'loc_nasr_city',
      imageUrl:
          'https://images.pexels.com/photos/7088524/pexels-photo-7088524.jpeg',
      priceStart: 320,
      isAvailable: true,
      about: 'service_provider_about_5',
      isVerified: true,
      yearsOfExperience: 12,
      isOnline: true,
    ),

    const ServiceProviderModel(
      id: 'd6',
      name: 'Dr. Nour Adel',
      categoryId: '1',
      subCategory: 'sub_gynecologist',
      rating: 4.8,
      reviewCount: 95,
      location: 'loc_heliopolis',
      imageUrl:
          'https://images.pexels.com/photos/4860427/pexels-photo-4860427.jpeg',
      priceStart: 400,
      isAvailable: false,
      about: 'service_provider_about_6',
      isVerified: false,
      yearsOfExperience: 7,
      isOnline: false,
    ),

    const ServiceProviderModel(
      id: 'd7',
      name: 'Dr. Youssef Magdy',
      categoryId: '1',
      subCategory: 'sub_orthopedic',
      rating: 4.5,
      reviewCount: 60,
      location: 'loc_giza',
      imageUrl:
          'https://images.pexels.com/photos/6759512/pexels-photo-6759512.jpeg',
      priceStart: 500,
      isAvailable: true,
      about: 'service_provider_about_7',
      isVerified: true,
      yearsOfExperience: 20,
      isOnline: true,
    ),

    const ServiceProviderModel(
      id: 'd8',
      name: 'Dr. Hanan Mostafa',
      categoryId: '1',
      subCategory: 'sub_neurologist',
      rating: 4.7,
      reviewCount: 110,
      location: 'loc_dokki',
      imageUrl:
          'https://images.pexels.com/photos/7575550/pexels-photo-7575550.jpeg',
      priceStart: 650,
      isAvailable: true,
      about: 'service_provider_about_8',
      isVerified: true,
      yearsOfExperience: 25,
      isOnline: false,
    ),

    const ServiceProviderModel(
      id: 'd9',
      name: 'Dr. Karim Nabil',
      categoryId: '1',
      subCategory: 'sub_psychiatrist',
      rating: 4.6,
      reviewCount: 55,
      location: 'loc_online',
      imageUrl:
          'https://images.pexels.com/photos/3184329/pexels-photo-3184329.jpeg',
      priceStart: 280,
      isAvailable: true,
      about: 'service_provider_about_9',
      isVerified: false,
      yearsOfExperience: 3,
      isOnline: true,
    ),
  ];

  static List<ServiceProviderModel> getByCategoryId(String categoryId) {
    return mockProviders.where((p) => p.categoryId == categoryId).toList();
  }
}
