// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/features/payment/data/repo/payment_repo.dart';
import 'package:servino_provider/features/payment/models/payment_gateway_model.dart';
import 'package:servino_provider/features/payment/models/payment_params.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';

class PaymentInstructionPage extends StatefulWidget {
  final PaymentParams params;
  final PaymentGatewayModel method;

  const PaymentInstructionPage({
    super.key,
    required this.params,
    required this.method,
  });

  @override
  State<PaymentInstructionPage> createState() => _PaymentInstructionPageState();
}

class _PaymentInstructionPageState extends State<PaymentInstructionPage> {
  File? _receiptImage;
  bool _isUploading = false;
  late PaymentRepository _repository;
  final TextEditingController _senderController = TextEditingController();

  @override
  void dispose() {
    _senderController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repository = PaymentRepository(api: DioConsumer(dio: Dio()));
  }

  Future<void> _pickReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('receipt_uploaded'.tr())));
    }
  }

  void _confirmTransfer() async {
    if (_senderController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sender_required'.tr())));
      return;
    }

    if (_receiptImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('receipt_required'.tr())));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Upload Receipt
      final imageUrl = await _repository.uploadReceipt(_receiptImage!);
      if (imageUrl == null) {
        throw Exception('Image upload failed');
      }

      // 2. Create Transaction
      final userProvider = context.read<UserProvider>();
      final userId = int.tryParse(userProvider.user?.id ?? '0') ?? 0;

      if (userId == 0) {
        throw Exception('User authentication error. Please login again.');
      }

      final transactionId = await _repository.createTransaction(
        userId: userId,
        amount: widget.params.amount,
        methodId: widget.method.id,
        methodName: widget.method.keyword,
        senderFrom: _senderController.text.trim(),
        receiptImageInfo: imageUrl,
        planId: widget.params.planId,
        isSubscription: widget.params.isSubscription,
        currency: widget.params.currency,
        description: widget.params.description,
        originalAmount: widget.params.originalAmount,
        discountPercentage: widget.params.discountPercentage,
        title: widget.params.title,
        deviceInfo:
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );

      if (transactionId != null && mounted) {
        setState(() {
          _isUploading = false;
        });
        // Navigate to Waiting Page
        AppRouter.navigateTo(
          context,
          Routes.paymentWaiting,
          arguments: {
            'params': widget.params, // Pass params
            'transactionId': transactionId,
          },
        );
      } else {
        throw Exception('Transaction creation failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'instruction_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
          const Positioned.fill(child: AnimatedBackground()),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 100.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 10.h),

                  // Amount Card (Premium Look)
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 130.h,
                          width: 140.w,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Image.network(
                              widget.method.getFullImageUrl(),
                              height: 120.h,
                              width: 140.w,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Icon(
                                Icons.payment,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'payment_fee_label'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.params.amount} ${widget.params.currency}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'instruction_title'.tr(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              widget.method.getInstructions(context),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark ? Colors.white : Colors.black,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Copy Field (Transfer Target)
                            if (widget.method.transferNumber != null &&
                                widget.method.transferNumber!.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: widget.method.transferNumber!,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied!')),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.backgroundDark
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.method.transferNumber!,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Courier',
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.copy,
                                        size: 20.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'copy_btn'.tr(),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Sender Number / ID Input
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: TextField(
                      controller: _senderController,
                      decoration: InputDecoration(
                        hintText: 'enter_sender_number'.tr(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Upload Area
                  GestureDetector(
                    onTap: _pickReceipt,
                    child: Container(
                      height: 180.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: _receiptImage != null
                              ? AppColors.primary
                              : isDark
                              ? Colors.grey[800]!
                              : Colors.grey[300]!,
                          style: _receiptImage != null
                              ? BorderStyle.solid
                              : BorderStyle.solid,
                        ),
                      ),
                      child: _receiptImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18.r),
                                  child: Image.file(
                                    _receiptImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.check,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 36.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'upload_receipt'.tr(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'receipt_required'.tr(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _confirmTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 8,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'confirm_transfer'.tr(),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
}
