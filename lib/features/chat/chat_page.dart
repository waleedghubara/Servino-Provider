// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:servino_provider/core/widgets/consultation_completion_dialog.dart';
import 'package:servino_provider/core/widgets/consultation_warning_dialog.dart';
import 'package:servino_provider/core/widgets/consultation_waiting_dialog.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/core/routes/app_router.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/model/message_model.dart';
import 'package:servino_provider/core/theme/colors.dart';
import 'package:servino_provider/core/widgets/animated_background.dart';
import 'package:servino_provider/core/widgets/chat_app_bar.dart';
import 'package:servino_provider/core/widgets/chat_input_field.dart';
import 'package:servino_provider/core/widgets/message_bubble.dart';
import 'package:servino_provider/features/chat/data/repo/chat_repo.dart';
import 'package:servino_provider/features/chat/logic/chat_provider.dart';
import 'package:servino_provider/core/providers/user_provider.dart';

import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final String? userName;
  final Map<String, dynamic>? initialArguments;
  const ChatPage({super.key, this.userName, this.initialArguments});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _otherUserId;
  String? _bookingId;
  String? _userName;
  String? _userImage;
  String? _bookingType;

  @override
  void initState() {
    super.initState();
    _parseArguments();
  }

  void _parseArguments() {
    // Basic argument parsing
    _userName = widget.userName;
    if (widget.initialArguments != null) {
      final args = widget.initialArguments!;
      _userName ??=
          args['clientName'] ??
          args['providerName'] ??
          args['userName'] ??
          args['name'];
      _userImage = args['providerImage'] ?? args['image'];
      _bookingId = args['bookingId']?.toString();

      // Prioritize isConsultation flag if present
      bool isCon = args['isConsultation'] == true;
      if (isCon) {
        _bookingType = 'consultation';
      } else {
        _bookingType = args['type']?.toString();
      }

      _otherUserId = args['userId']?.toString();
    }

    // Defer initialization to after build to access context/providers safely if needed
    // ChatProvider is initialized in _ChatView
  }

  @override
  Widget build(BuildContext context) {
    if (_otherUserId == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text("Error: No User ID provided")),
      );
    }

    final user = context.read<UserProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider(
      create: (_) => ChatProvider(
        repository: ChatRepository(api: DioConsumer(dio: Dio())),
        currentUserId: user.id.toString(),
      ),
      child: _ChatView(
        otherUserId: _otherUserId!,
        userName: _userName ?? 'User',
        userImage: _userImage ?? '',
        bookingId: _bookingId,
        bookingType: _bookingType,
        currentUserName: user.name,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String otherUserId;
  final String userName;
  final String userImage;
  final String? bookingId;
  final String? bookingType;
  final String currentUserName;

  const _ChatView({
    required this.otherUserId,
    required this.userName,
    required this.userImage,
    this.bookingId,
    this.bookingType,
    required this.currentUserName,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    // Initialize provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().init(
        widget.otherUserId,
        bookingId: widget.bookingId,
        otherUserRole: 'client',
        otherUserName: widget.userName,
        currentUserName: widget.currentUserName.isNotEmpty
            ? widget.currentUserName
            : 'Me',
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
      }
    } catch (e) {
      // debugPrint("Error starting recorder: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        if (!mounted) return;
        context.read<ChatProvider>().sendAudio(File(path));
      }
    } catch (e) {
      // debugPrint("Error stopping recorder: $e");
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
    } catch (e) {
      // ignore
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Reverse list view, 0 is bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSwipe(MessageModel message) {
    context.read<ChatProvider>().setReplyingTo(message);
  }

  void _cancelReply() {
    context.read<ChatProvider>().setReplyingTo(null);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      if (!mounted) return;
      context.read<ChatProvider>().sendImage(File(image.path));
    }
  }

  Future<void> _sendLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('chat_location_denied'.tr())));
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading
      context.read<ChatProvider>().sendLocation(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('chat_location_error'.tr())));
    }
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Wrap(
          spacing: 40.w,
          runSpacing: 20.h,
          alignment: WrapAlignment.center,
          children: [
            _AttachmentIcon(
              Icons.image,
              Colors.purple,
              'chat_attachment_image'.tr(),
              () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            _AttachmentIcon(
              Icons.camera_alt,
              Colors.blue,
              'chat_attachment_camera'.tr(),
              () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _AttachmentIcon(
              Icons.videocam,
              Colors.pink,
              'chat_attachment_video'.tr(),
              () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (video != null) {
                  if (!mounted) return;
                  context.read<ChatProvider>().sendVideo(File(video.path));
                }
              },
            ),
            _AttachmentIcon(
              Icons.location_on,
              Colors.green,
              'chat_attachment_location'.tr(), // Provide key or text
              () {
                Navigator.pop(context);
                _sendLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;
            _handleBack(context);
          },
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              _cancelReply();
            },
            child: Stack(
              children: [
                const Positioned.fill(child: AnimatedBackground()),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: ChatAppBar(
                    userName: widget.userName,
                    userImage: widget.userImage.isEmpty
                        ? 'https://via.placeholder.com/150'
                        : widget.userImage,
                    isOnline: provider.isOtherUserOnline,
                    inviteeId: widget.otherUserId,
                    onBackTap: () => _handleBack(context),
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: provider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: _scrollController,
                                reverse: true, // Standard chat behavior
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                itemCount: provider.messages.length,
                                itemBuilder: (context, index) {
                                  final message = provider.messages[index];
                                  return Dismissible(
                                    key: ValueKey(message.id),
                                    direction: DismissDirection.horizontal,
                                    confirmDismiss: (direction) async {
                                      _onSwipe(message);
                                      return false;
                                    },
                                    background: Container(
                                      color: Colors.transparent,
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(left: 20.w),
                                      child: Icon(
                                        Icons.reply,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.transparent,
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: 20.w),
                                      child: Icon(
                                        Icons.reply,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    child: MessageBubble(
                                      message: message,
                                      onReplyTap: () {
                                        // Navigate to original message?
                                        // For now just highlight logic if implemented
                                      },
                                      onSwipe: () => _onSwipe(message),
                                      highlightedMessageId:
                                          provider.replyingTo?.id,
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Reply Preview
                      if (provider.replyingTo != null)
                        Container(
                          color: Colors.grey.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.reply, color: AppColors.primary),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.replyingTo!.isMe
                                          ? widget.currentUserName
                                          : widget.userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      MessageModel.getSnippet(
                                        provider.replyingTo!.type,
                                        provider.replyingTo!.content,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _cancelReply,
                              ),
                            ],
                          ),
                        ),

                      ChatInputField(
                        onSendMessage: (text) {
                          provider.sendMessage(text);
                          _scrollToBottom();
                        },
                        onAttachmentTap: _showAttachmentSheet,
                        onRecording: (isRecording) {
                          if (isRecording) {
                            _startRecording();
                          }
                        },
                        onStopRecording: _stopRecording,
                        onCancelRecording: _cancelRecording,
                        isSending: provider.isSending,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    // If no bookingId, just pop
    if (widget.bookingId == null) {
      Navigator.of(context).pop();
      return;
    }

    final int? bookingId = int.tryParse(widget.bookingId!);
    if (bookingId == null) {
      Navigator.of(context).pop();
      return;
    }

    // Strictly check if it is a consultation
    // If bookingType is false/null, we assume it is NOT a consultation.
    bool isConsultation = false;
    if (widget.bookingType != null) {
      final type = widget.bookingType!.toLowerCase();
      if (type.contains('consultation') ||
          type.contains('istishara') ||
          type.contains('estishara')) {
        isConsultation = true;
      }
    }

    if (!isConsultation) {
      Navigator.of(context).pop();
      return;
    }

    // Show Completion Dialog
    final chatRepository = context.read<ChatProvider>().repository;

    showDialog(
      context: context,
      builder: (context) => ConsultationCompletionDialog(
        bookingId: bookingId,
        repository: chatRepository,
        onYes: () async {
          Navigator.of(context).pop(); // Close completion dialog

          // Show Waiting Dialog and wait for result
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => ConsultationWaitingDialog(
              bookingId: bookingId,
              repository: chatRepository,
              onSupport: () {
                Navigator.of(context).pop(false);
                Navigator.pushNamed(context, '/support');
              },
            ),
          );

          if (result == true) {
            // Use navigatorKey to avoid "Looking up a deactivated widget's ancestor is unsafe"
            // This happens because ChatPage might be unmounted/deactivated when this runs
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              Routes.main,
              (route) => false,
            );
          }
        },
        onNo: () {
          Navigator.of(context).pop(); // Close completion dialog

          // Show Warning Dialog
          showDialog(
            context: context,
            builder: (context) => ConsultationWarningDialog(
              onBack: () {
                Navigator.of(context).pop(); // Close warning dialog
                // Do not exit chat, let them stay to complete it later
              },
              onSupport: () {
                Navigator.of(context).pop();
                // Navigate to support if implemented, or just close
                Navigator.pushNamed(context, '/support');
              },
            ),
          );
        },
        onSupport: () {
          // Handle support if needed
        },
      ),
    );
  }
}

class _AttachmentIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentIcon(this.icon, this.color, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
