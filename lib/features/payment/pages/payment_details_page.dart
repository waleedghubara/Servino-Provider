// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/features/payment/pages/payment_success_page.dart';
import 'package:servino_provider/features/payment/models/payment_params.dart';

class PaymentDetailsPage extends StatefulWidget {
  final PaymentParams params;

  const PaymentDetailsPage({super.key, required this.params});

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saveCard = true;
  bool _isProcessing = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        AppRouter.navigateTo(
          context,
          Routes.paymentSuccess,
          arguments: PaymentSuccessPageParams(
            params: widget.params, // Pass params
            status: PaymentStatus.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'payment_details_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 24.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Credit Card Preview
                          _buildCardPreview(),

                          SizedBox(height: 32.h),

                          // Form Container
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _cardNumberController,
                                  label: 'card_number',
                                  hint: '0000 0000 0000 0000',
                                  keyboardType: TextInputType.number,
                                  icon: Icons.credit_card,
                                  onChanged: (val) => setState(() {}),
                                ),
                                SizedBox(height: 20.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _expiryController,
                                        label: 'expiry_date',
                                        hint: 'MM/YY',
                                        keyboardType: TextInputType.datetime,
                                        icon: Icons.calendar_today,
                                        onChanged: (val) => setState(() {}),
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _cvvController,
                                        label: 'cvv',
                                        hint: '123',
                                        keyboardType: TextInputType.number,
                                        icon: Icons.lock_outline,
                                        isObscure: true,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                _buildTextField(
                                  controller: _holderNameController,
                                  label: 'card_holder_name',
                                  hint: 'John Doe',
                                  icon: Icons.person_outline,
                                  onChanged: (val) => setState(() {}),
                                ),
                                SizedBox(height: 24.h),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'save_card'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  activeColor: AppColors.primary,
                                  value: _saveCard,
                                  onChanged: (val) {
                                    setState(() {
                                      _saveCard = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24.h),

                          // Secure Badge
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 16.sp,
                                  color: Colors.green[700],
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'payment_secure_badge'.tr(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          0.6,
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              '${'pay'.tr()} ${widget.params.amount} ${widget.params.currency}', // Show amount on button
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      height: 220.h,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F71), // Visa Blue/Dark Navy
            const Color(0xFF005A9C).withOpacity(0.9), // Lighter Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1F71).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Circle Pattern
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chip Icon
                  Container(
                    width: 45.w,
                    height: 35.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(6.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFF7E98E),
                          Color(0xFFD4AF37),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      Icons.memory,
                      color: Colors.black45,
                      size: 24.sp,
                    ),
                  ),
                  Icon(Icons.credit_card, color: Colors.white, size: 32.sp),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cardNumberController.text.isEmpty
                        ? '**** **** **** ****'
                        : _cardNumberController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      letterSpacing: 2,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'card_preview_holder'.tr().toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10.sp,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _holderNameController.text.isEmpty
                                ? 'card_name_placeholder'.tr()
                                : _holderNameController.text.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'card_preview_expires'.tr().toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10.sp,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _expiryController.text.isEmpty
                                ? 'MM/YY'
                                : _expiryController.text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isObscure = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isObscure,
          onChanged: onChanged,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22.sp),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'field_required'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }
}
