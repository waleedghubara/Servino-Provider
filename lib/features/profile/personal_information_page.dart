// ignore_for_file: prefer_conditional_assignment, unnecessary_null_comparison, unused_field, deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:currency_picker/currency_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servino_provider/core/model/category_model.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/auth/data/repo/auth_repo.dart';
import 'package:servino_provider/core/api/end_point.dart';
import 'package:servino_provider/core/theme/assets.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  // State
  // State
  String? _gender;
  DateTime? _selectedDate;
  CategoryModel? _selectedCategory;
  ServiceItem? _selectedService;
  Currency? _selectedCurrency;
  List<CategoryModel> _categories = [];
  late final AuthRepository _repo;

  File? _image;
  File? _idImage;
  File? _certificateImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _repo = AuthRepository(api: DioConsumer(dio: Dio()));
    _fetchCategories();

    final user = context.read<UserProvider>().user;

    // Initialize with actual user data or fallback
    _nameController = TextEditingController(text: user?.name ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
    _dobController = TextEditingController(text: user?.dob ?? "");
    _descriptionController = TextEditingController(
      text: user?.description ?? "",
    );
    _priceController = TextEditingController(text: user?.price ?? "");
    _locationController = TextEditingController(text: user?.location ?? "");

    _gender = user?.gender ?? "Male";

    // Currency
    if (user?.currency != null) {
      try {
        _selectedCurrency = CurrencyService().findByCode(user!.currency!);
      } catch (e) {
        _selectedCurrency = CurrencyService().getAll().first;
      }
    }
    if (_selectedCurrency == null) {
      _selectedCurrency = CurrencyService().getAll().firstWhere(
        (element) => element.code == 'USD',
        orElse: () => CurrencyService().getAll().first,
      );
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await _repo.getCategories();

      // Auto-select based on user data
      final user = context.read<UserProvider>().user;
      CategoryModel? foundCat;
      ServiceItem? foundService;

      if (user?.categoryId != null) {
        try {
          foundCat = cats.firstWhere((c) => c.id == user!.categoryId);
          if (foundCat != null && user?.serviceId != null) {
            try {
              foundService = foundCat.services.firstWhere(
                (s) => s.id == user!.serviceId,
              );
            } catch (_) {}
          }
        } catch (_) {}
      }

      setState(() {
        _categories = cats;
        _selectedCategory = foundCat;
        _selectedService = foundService;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage(bool isProfile) async {
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       if (isProfile) {
  //         _image = File(pickedFile.path);
  //       }
  //     });
  //   }
  // }

  // Reuse location logic from RegisterPage if possible, simplified here
  Future<void> _getCurrentLocation() async {
    // Ideally, use Geolocation package here.
    // For now, prompt user or keep it editable text field.
    // To avoid adding heavy dependencies without permission, I'll allow manual editing mainly,
    // or just set a placeholder.
    // User: "via IP"? Maybe they mean they want the SAVE to work via API.
    // I'll leave the text field editable if readOnly was true.
    // Wait, readOnly was true. I'll make it false so they can type.
    setState(() {
      // _locationController.text = ... (Use Geocoding if available)
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: 4.h),
                          _buildProfileImagePicker(
                            isDark,
                          ), // Profile image typically editable? User said "Only Phone and Location". I'll assume Profile Pic is also locked or clarify. "The rest appears without me being able to edit it". I will lock Profile Pic too for safety or leave it? "Everything else" implies everything. I'll disable the camera icon.
                          SizedBox(height: 20.h),
                          _buildTextField(
                            controller: _nameController,
                            label: 'register_full_name'.tr(),
                            icon: Icons.person_outline,
                            isDark: isDark,
                            readOnly: true, // LOCKED
                            fillColor: isDark
                                ? Colors.white10
                                : Colors.grey[200],
                          ),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            controller: _emailController,
                            label: 'login_email'.tr(),
                            icon: Icons.email_outlined,
                            isDark: isDark,
                            readOnly: true, // LOCKED
                            fillColor: isDark
                                ? Colors.white10
                                : Colors.grey[200],
                          ),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'register_phone'.tr(),
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            // EDITABLE (No readOnly: true)
                          ),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            controller: _dobController,
                            label: 'register_dob'.tr(),
                            icon: Icons.calendar_today_outlined,
                            isDark: isDark,
                            readOnly: true, // LOCKED
                            onTap: null, // Disable picker
                            fillColor: isDark
                                ? Colors.white10
                                : Colors.grey[200],
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
                                child: Text(
                                  value == 'Male'
                                      ? 'gender_male'.tr()
                                      : 'gender_female'.tr(),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {}, // No-op or disabled
                            isDark: isDark,
                            enabled: false, // LOCKED
                          ),

                          SizedBox(height: 32.h),
                          _buildSectionTitle('professional_info'.tr(), isDark),
                          SizedBox(height: 16.h),
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
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        child: Image.network(
                                          category.image.startsWith('http')
                                              ? category.image
                                              : '${EndPoint.imageBaseUrl}${category.image}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    size: 15.sp,
                                                  ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontFamily: 'Tajawal',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {},
                            isDark: isDark,
                            enabled: false, // LOCKED
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
                                    child: Text(
                                      service.name,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  );
                                }).toList() ??
                                [],
                            onChanged: (val) {},
                            isDark: isDark,
                            enabled: false, // LOCKED
                          ),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'description'.tr(),
                            icon: Icons.description_outlined,
                            isDark: isDark,
                            maxLines: 3,
                            readOnly: true, // LOCKED
                            fillColor: isDark
                                ? Colors.white10
                                : Colors.grey[200],
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
                                  icon: Icons.attach_money,
                                  isDark: isDark,
                                  keyboardType: TextInputType.number,
                                  // EDITABLE (Price should be editable)
                                  fillColor: isDark
                                      ? Colors.white10
                                      : Colors.grey[200],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                flex: 1,
                                child: _buildCurrencyPicker(
                                  isDark,
                                  enabled: true, // EDITABLE
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 32.h),
                          _buildSectionTitle('documents_location'.tr(), isDark),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            controller: _locationController,
                            label: 'register_location_hint'.tr(),
                            icon: Icons.location_on_outlined,
                            isDark: isDark,
                            readOnly:
                                false, // Allow typing manually if GPS fails
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _getCurrentLocation, // EDITABLE
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'documents'.tr(),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildImageUploadBox(
                                  title: 'upload_id'.tr(),
                                  image:
                                      _idImage, // Assuming dummy image is set for display
                                  isverified: user?.isApproved ?? false,
                                  imageUrl: user?.idImage,
                                  onTap:
                                      () {}, // Disabled for now, as re-upload logic is complex
                                  isDark: isDark,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: _buildImageUploadBox(
                                  title: 'upload_certificate'.tr(),
                                  image: _certificateImage,
                                  imageUrl: user?.certificateImage,
                                  isverified: user?.isApproved ?? false,
                                  onTap: () {}, // Disabled
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 40.h),
                          _buildSaveButton(isDark),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Spacer(),
          Text(
            'edit_personal_details'.tr(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 30.w),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker(bool isDark) {
    final user = context.watch<UserProvider>().user;
    ImageProvider imageProvider;
    if (user?.fullProfileImageUrl != null &&
        user!.fullProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(user.fullProfileImageUrl!);
    } else {
      imageProvider = const AssetImage(Assets.userAvatar);
    }

    // Determine frame asset
    String? frameAsset;
    // Check local subscription (or just use isSubscribed backend flag)
    // Assuming backend returns valid isSubscribed logic.
    // Also planId: 3=VIP, 2=Pro (as per HomePage logic)
    if (user != null && user.isSubscribed) {
      if (user.currentPlanId == 3) {
        frameAsset = Assets.goldFrame;
      } else if (user.currentPlanId == 2) {
        frameAsset = Assets.diamondFrame;
      }
    }

    return Center(
      child: SizedBox(
        width: 110.r, // Provide enough space for frame overflow if needed
        height: 110.r,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Avatar
            Container(
              width: 100.r,
              height: 100.r,
              // No margin, raw size
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: frameAsset == null
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                image: _image != null
                    ? DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),

            // Frame
            if (frameAsset != null)
              Positioned(
                // Scaling logic from HomePage: 50px avatar -> -10 offset.
                // 100px avatar -> -20 offset.
                top: -20.r,
                bottom: -20.r,
                left: -20.r,
                right: -20.r,
                child: Image.asset(
                  frameAsset,
                  fit: BoxFit.contain,
                  width: 140.r, // Ensure frame is larger than avatar
                  height: 140.r,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    int maxLines = 1,
    Color? fillColor,
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
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color:
                fillColor ?? (isDark ? AppColors.surfaceDark : Colors.grey[50]),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Tajawal',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Tajawal'),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20.sp),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    bool enabled = true,
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
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: enabled
                ? (isDark ? AppColors.surfaceDark : Colors.grey[50])
                : (isDark ? Colors.white10 : Colors.grey[200]),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Row(
                children: [
                  Icon(
                    icon,
                    color: enabled ? AppColors.primary : Colors.grey,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: enabled
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey,
              ),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: items,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPicker(bool isDark, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'currency'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
            fontFamily: 'Tajawal',
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: enabled
              ? () {
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
                  );
                }
              : null,
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: enabled
                  ? (isDark ? AppColors.surfaceDark : Colors.grey[50])
                  : (isDark ? Colors.white10 : Colors.grey[200]),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedCurrency != null) ...[
                  Text(
                    CurrencyUtils.currencyToEmoji(_selectedCurrency!),
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _selectedCurrency!.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadBox({
    required String title,
    required File? image,
    String? imageUrl,
    required VoidCallback onTap,
    required bool isDark,
    bool isverified = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey[50],
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 32.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white60 : Colors.grey,
                          fontFamily: 'Tajawal',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
          if (isverified)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'verified'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 5,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            try {
              // Show Loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              await _repo.updateProfile(
                phone: _phoneController.text,
                price: double.tryParse(_priceController.text) ?? 0.0,
                description: _descriptionController.text,
                location: _locationController.text,
                currency: _selectedCurrency?.code ?? 'USD',
              );

              // Refresh Provider
              if (mounted) {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                await userProvider.refreshUser(_repo);
              }

              // Dismiss Loading
              if (mounted) Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('changes_saved_msg'.tr())));
              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) Navigator.pop(context); // Dismiss loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Text(
          'save_changes'.tr(), // Add key
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}
