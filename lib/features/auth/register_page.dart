// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'dart:ui'; // Required for PathMetric

import 'package:alert_info/alert_info.dart';
import 'package:animate_do/animate_do.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servino_provider/core/model/category_model.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/features/auth/data/repo/auth_repo.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/api/end_point.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  List<CategoryModel> _categories = [];
  late final AuthRepository _repo;

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _dobController = TextEditingController();

  String? _gender;
  DateTime? _selectedDate;
  CategoryModel? _selectedCategory;
  ServiceItem? _selectedService;
  Currency? _selectedCurrency;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  File? _image;
  File? _idImage;
  File? _certificateImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _repo = AuthRepository(api: DioConsumer(dio: Dio()));
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await _repo.getCategories();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      // debugPrint('Error fetching categories: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _submitRegistration();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitRegistration() async {
    if (_selectedCategory == null ||
        _selectedService == null ||
        _image == null ||
        _idImage == null) {
      AlertInfo.show(
        context: context,
        text: 'please_fill_all_required_fields'.tr(),
      );
      return;
    }

    try {
      await _repo.register(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        dob: _dobController.text,
        gender: _gender ?? 'Male',
        categoryId: _selectedCategory!.id,
        serviceId: _selectedService!.id,
        experienceYears: _experienceYearsController.text,
        description: _descriptionController.text,
        price: _priceController.text,
        currency: _selectedCurrency?.code ?? 'USD',
        location: _locationController.text,
        profileImagePath: _image!.path,
        idImagePath: _idImage!.path,
        certificateImagePath: _certificateImage?.path,
      );

      HapticFeedback.lightImpact();
      if (mounted) {
        AlertInfo.show(
          context: context,
          text: 'Successful Registration'.tr(), // Add key if needed
        );
        // Delay slighty so user sees the alert
        Future.delayed(const Duration(seconds: 1), () {
          AppRouter.navigateTo(
            context,
            Routes.otp,
            arguments: {'isRegister': true, 'email': _emailController.text},
          );
        });
      }
    } catch (e) {
      if (mounted) {
        AlertInfo.show(context: context, text: e.toString());
      }
    } finally {
      if (mounted) {}
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.black : Colors.black,
            ),
            dialogBackgroundColor: isDark
                ? AppColors.surfaceDark
                : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd', 'en').format(picked);
      });
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _pickIdImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _idImage = File(pickedFile.path));
  }

  Future<void> _pickCertificateImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _certificateImage = File(pickedFile.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('location_services_disabled'.tr())),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location_permissions_denied'.tr())),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('location_permissions_permanently_denied'.tr())),
      );
      return;
    }

    // Show loading state directly in the text field
    setState(() {
      _locationController.text = 'getting_location'.tr();
    });

    try {
      Position position = await Geolocator.getCurrentPosition();

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Construct address favoring specific details
          List<String?> addressParts = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country,
          ];

          // Filter out nulls or empty strings
          String address = addressParts
              .where((part) => part != null && part.isNotEmpty)
              .toSet() // Remove duplicates like if street == locality
              .join(', ');

          if (mounted) {
            setState(() {
              _locationController.text = address;
            });
          }
        } else {
          // Fallback if no address found
          if (mounted) {
            setState(() {
              _locationController.text =
                  "${position.latitude}, ${position.longitude}";
            });
          }
        }
      } catch (e) {
        // Fallback: If native geocoding fails, try Web API (Nominatim)
        // debugPrint("Native Geocoding failed: $e");

        try {
          String? webAddress = await _getAddressFromWeb(
            position.latitude,
            position.longitude,
            context.locale.languageCode,
          );

          if (webAddress != null && webAddress.isNotEmpty) {
            if (mounted) {
              setState(() {
                _locationController.text = webAddress;
              });
            }
          } else {
            // Second Fallback: Coordinates
            if (mounted) {
              setState(() {
                _locationController.text =
                    "${position.latitude}, ${position.longitude}";
              });
            }
          }
        } catch (webError) {
          // Final Fallback: Coordinates
          if (mounted) {
            setState(() {
              _locationController.text =
                  "${position.latitude}, ${position.longitude}";
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationController.text = '';
        });

        AlertInfo.show(context: context, text: 'error_get_location'.tr());
      }
    }
  }

  Future<String?> _getAddressFromWeb(
    double lat,
    double lng,
    String lang,
  ) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'accept-language': lang,
        },
        options: Options(headers: {'User-Agent': 'Servino_Provider_App/1.0'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final addr = data['address'];
        if (addr != null) {
          List<String?> parts = [
            addr['road'],
            addr['neighbourhood'] ?? addr['suburb'],
            addr['city'] ?? addr['town'] ?? addr['village'],
            addr['state'],
            addr['country'],
          ];
          return parts
              .where((p) => p != null && p.isNotEmpty)
              .toSet()
              .join(', ');
        }
        return data['display_name'];
      }
    } catch (e) {
      // debugPrint("Web Geocoding failed: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [AppColors.primary2, AppColors.backgroundDark]
                      : [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.background,
                        ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildCustomHeader(isDark),
                SizedBox(height: 10.h),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      padding: EdgeInsets.only(top: 10.h),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildPersonalStep(isDark),
                          _buildProfessionalStep(isDark),
                          _buildDocumentsStep(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomNavigation(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(0, 'personal_info'.tr(), Icons.person, isDark),
          _buildConnector(0, isDark),
          _buildStepIndicator(1, 'professional_info'.tr(), Icons.work, isDark),
          _buildConnector(1, isDark),
          _buildStepIndicator(
            2,
            'documents_location'.tr(),
            Icons.file_present,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    int stepIndex,
    String title,
    IconData icon,
    bool isDark,
  ) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? AppColors.primary
                : (isDark ? Colors.grey[800] : Colors.grey[300]),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w700,
            color: isActive
                ? AppColors.primary
                : (isDark ? Colors.grey[500] : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int stepIndex, bool isDark) {
    final isCompleted = _currentStep > stepIndex;

    return Expanded(
      child: Container(
        height: 2.h,
        margin: EdgeInsets.only(bottom: 20.h),
        color: isCompleted
            ? AppColors.primary
            : (isDark ? Colors.grey[800] : Colors.grey[300]),
      ),
    );
  }

  // REVERTED: Using original structure without _buildCardField wrapper
  Widget _buildPersonalStep(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKeys[0],
        child: Column(
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: _buildProfileImagePicker(isDark),
            ),
            SizedBox(height: 20.h),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'register_full_name'.tr(),
                    hint: 'register_full_name_hint'.tr(),
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _emailController,
                    label: 'login_email'.tr(),
                    hint: 'login_email_hint'.tr(),
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'register_phone'.tr(),
                    hint: 'register_phone_hint'.tr(),
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _dobController,
                    label: 'register_dob'.tr(),
                    hint: '1990-01-01',
                    icon: Icons.calendar_today_outlined,
                    isDark: isDark,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  SizedBox(height: 16.h),
                  _buildDropdown<String>(
                    label: 'register_gender'.tr(),
                    hint: 'gender_male'.tr(),
                    value: _gender,
                    icon: Icons.wc,
                    items: ['Male', 'Female'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == 'Male' ? Icons.male : Icons.female,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              value == 'Male'
                                  ? 'gender_male'.tr()
                                  : 'gender_female'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Tajawal',
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) => setState(() => _gender = newValue),
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'register_password'.tr(),
                    hint: '******',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'register_confirm_password'.tr(),
                    hint: '******',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isDark: isDark,
                    isConfirm: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalStep(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKeys[1],
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Column(
            children: [
              _buildDropdown<CategoryModel>(
                label: 'work_type'.tr(),
                hint: 'select_work_type'.tr(),

                value: _selectedCategory,
                icon: Icons.work_outline_outlined,
                items: _categories.map((category) {
                  return DropdownMenuItem<CategoryModel>(
                    value: category,
                    child: Row(
                      children: [
                        Container(
                          width: 30.r,
                          height: 30.r,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              category.image.startsWith('http')
                                  ? category.image
                                  : '${EndPoint.imageBaseUrl}${category.image}', // Handle full URL or relative
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image_not_supported, size: 15.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tajawal',
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _selectedService = null;
                  });
                },
                isDark: isDark,
              ),
              SizedBox(height: 16.h),
              _buildDropdown<ServiceItem>(
                label: 'service'.tr(),
                hint: 'select_service'.tr(),
                value: _selectedService,
                icon: Icons.group_work_outlined,
                items:
                    _selectedCategory?.services.map((service) {
                      return DropdownMenuItem<ServiceItem>(
                        value: service,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Tajawal',
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList() ??
                    [],
                onChanged: (newValue) =>
                    setState(() => _selectedService = newValue),
                isDark: isDark,
                enabled: _selectedCategory != null,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _descriptionController,
                label: 'description'.tr(),
                hint: 'register_description_hint'.tr(),
                icon: Icons.description_outlined,
                isDark: isDark,
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'consultation_price'.tr(),
                      hint: '00.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'currency'
                              .tr(), // Make sure to add this key or use a static string for now
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: () {
                            showCurrencyPicker(
                              context: context,
                              showFlag: true,
                              showCurrencyName: true,
                              showCurrencyCode: true,
                              onSelect: (Currency currency) {
                                setState(() {
                                  _selectedCurrency = currency;
                                });
                              },
                              theme: CurrencyPickerThemeData(
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                titleTextStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                subtitleTextStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                                currencySignTextStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 56.h, // Approx height of text field
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.transparent
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_selectedCurrency != null) ...[
                                  Text(
                                    CurrencyUtils.currencyToEmoji(
                                      _selectedCurrency!,
                                    ),
                                    style: TextStyle(fontSize: 20.sp),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _selectedCurrency!.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    'select'.tr(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _experienceYearsController,
                label: 'experience_years'.tr(),
                hint: '05',
                icon: Icons.work_outline,
                keyboardType: TextInputType.number,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsStep(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKeys[2],
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Column(
            children: [
              _buildTextField(
                controller: _locationController,
                label: 'location'.tr(),
                hint: 'register_location_hint'.tr(),
                icon: Icons.location_on_outlined,
                isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(Icons.my_location, color: AppColors.primary),
                  onPressed: _getCurrentLocation,
                ),
              ),
              SizedBox(height: 24.h),

              // ID Card Upload - Credit Card Aspect Ratio (~1.586)
              _buildDocumentUploadArea(
                label: 'id_card_image'.tr(),
                image: _idImage,
                onTap: _pickIdImage,
                isDark: isDark,
                aspectRatio: 8.56 / 5.4, // Standard Credit Card Ratio
                icon: Icons.credit_card,
              ),

              SizedBox(height: 24.h),

              // Certificate Upload - A4 Aspect Ratio (~0.7) or Document style
              _buildDocumentUploadArea(
                label: 'certificate_image_optional'.tr(),
                image: _certificateImage,
                onTap: _pickCertificateImage,
                isDark: isDark,
                aspectRatio: 21.0 / 29.7, // A4 aspect ratio (Portrait)
                // Or for landscape certificate: 29.7 / 21.0
                icon: Icons.description,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUploadArea({
    required String label,
    required File? image,
    required VoidCallback onTap,
    required bool isDark,
    required double aspectRatio,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
            fontFamily: 'Tajawal',
          ),
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: CustomPaint(
            painter: _DottedBorderPainter(
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              strokeWidth: 2,
              gap: 5,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(2), // Space for border
              constraints: BoxConstraints(minHeight: 150.h),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(image, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 40.sp,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'upload_image'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImagePicker(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: () => _pickImage(true),
        child: Stack(
          children: [
            Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                image: _image != null
                    ? DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: _image == null
                  ? Icon(
                      Icons.person,
                      size: 50.sp,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(
                  'back'.tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: Text(
                _currentStep == 2 ? 'register_register'.tr() : 'next'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RESTORED: Original text field style
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword
              ? (isConfirm ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16.sp,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'field_required'.tr();
            }
            if (isPassword && isConfirm) {
              if (value != _passwordController.text) {
                return 'passwords_dont_match'.tr();
              }
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF5F6FA),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 18.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22.sp),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirm
                              ? _isConfirmPasswordVisible
                              : _isPasswordVisible)
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirm) {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        } else {
                          _isPasswordVisible = !_isPasswordVisible;
                        }
                      });
                    },
                  )
                : suffixIcon,
          ),
        ),
      ],
    );
  }

  // RESTORED: Original dropdown style
  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required bool isDark,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF5F6FA),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 18.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22.sp),
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: (value) => value == null ? 'field_required'.tr() : null,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          hint: Text(
            hint,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final Path path = Path()..addRRect(rrect);

    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
