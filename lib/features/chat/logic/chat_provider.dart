import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:servino_provider/core/model/message_model.dart';
import 'package:servino_provider/features/chat/data/repo/chat_repo.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ChatRepository _repository;
  final String _currentUserId;

  // State
  ChatRepository get repository => _repository;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOtherUserOnline = false;

  // Polling
  Timer? _pollingTimer;
  final int _pollingIntervalMs = 5000;
  final int _maxPollingIntervalMs = 10000;
  DateTime? _lastUserActivity;
  late String _otherUserId;
  String? _bookingId;
  String _otherUserRole = 'client';
  String _otherUserName = '';
  String _currentUserName = '';

  List<MessageModel> get messages {
    return _messages;
  }

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isOtherUserOnline => _isOtherUserOnline;
  MessageModel? _replyingTo;
  MessageModel? get replyingTo => _replyingTo;

  void setReplyingTo(MessageModel? message) {
    _replyingTo = message;
    notifyListeners();
  }

  ChatProvider({
    required ChatRepository repository,
    required String currentUserId,
  }) : _repository = repository,
       _currentUserId = currentUserId {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startAdaptivePolling();
      _repository.updateUserStatus(_currentUserId, true, role: 'provider');
    } else if (state == AppLifecycleState.paused) {
      stopPolling();
      _repository.updateUserStatus(_currentUserId, false, role: 'provider');
    }
  }

  void init(
    String otherUserId, {
    String? bookingId,
    String otherUserRole = 'client',
    String otherUserName = '',
    String currentUserName = '',
  }) {
    _otherUserId = otherUserId;
    _bookingId = bookingId;
    _otherUserRole = otherUserRole;
    _otherUserName = otherUserName;
    _currentUserName = currentUserName;
    loadMessages(refresh: true);
    startAdaptivePolling();
    _repository.updateUserStatus(_currentUserId, true, role: 'provider');
  }

  // --- Core Logic ---

  Future<void> loadMessages({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      notifyListeners();
    }

    // 1. Load Local Messages First (Instant)
    try {
      final localMsgs = await _repository.getLocalMessages(_otherUserId);
      if (localMsgs.isNotEmpty) {
        // Sort: Newest first
        localMsgs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _messages = localMsgs;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading local messages: $e");
    }

    // 2. Fetch Remote Messages (Background Sync)
    try {
      final fetched = await _repository.getMessages(_otherUserId);
      // Sort: Newest first
      fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _messages = fetched;

      // Mark as read if we have new messages from other user
      _markAsReadIfNeeded();

      // Initial status check
      await _fetchUserStatus();
    } catch (e) {
      debugPrint("Error loading messages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _markAsReadIfNeeded() {
    // If we have messages from the other user that are not read/seen, mark them.
    bool hasUnread = _messages.any(
      (m) => !m.isMe && m.status != MessageStatus.read,
    );

    if (hasUnread) {
      _repository.markMessagesAsRead(_otherUserId, role: _otherUserRole);
    }
  }

  // --- Polling ---

  void startAdaptivePolling() {
    stopPolling();
    _poll();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _poll() async {
    if (_otherUserId.isEmpty) return;

    int interval = _pollingIntervalMs;
    // Adaptive interval logic...
    if (_lastUserActivity != null &&
        DateTime.now().difference(_lastUserActivity!).inSeconds > 30) {
      interval = _maxPollingIntervalMs;
    }

    _pollingTimer = Timer(Duration(milliseconds: interval), () async {
      await Future.wait([_fetchUpdates(), _fetchUserStatus()]);
      if (_pollingTimer != null) _poll();
    });
  }

  Future<void> _fetchUserStatus() async {
    try {
      final statusData = await _repository.getUserStatus(
        _otherUserId,
        role: _otherUserRole,
      );
      if (statusData != null) {
        final isOnline =
            statusData['is_online'] == true || statusData['is_online'] == '1';
        if (_isOtherUserOnline != isOnline) {
          _isOtherUserOnline = isOnline;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user status: $e");
    }
  }

  Future<void> _fetchUpdates() async {
    try {
      final fetched = await _repository.getMessages(_otherUserId);
      fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      bool hasChanges = false;
      if (fetched.length != _messages.length) {
        hasChanges = true;
      } else {
        for (int i = 0; i < fetched.length; i++) {
          if (i >= _messages.length) break;
          if (fetched[i].id != _messages[i].id ||
              fetched[i].status != _messages[i].status) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        _messages = fetched;
        _markAsReadIfNeeded();
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  // --- Sending ---

  void userActivityDetected() {
    _lastUserActivity = DateTime.now();
  }

  Future<void> sendMessage(String text) async {
    _send(content: text, type: MessageType.text);
  }

  Future<void> sendImage(File file) async {
    _uploadAndSend(file: file, type: MessageType.image);
  }

  Future<void> sendVideo(File file) async {
    _uploadAndSend(file: file, type: MessageType.video);
  }

  Future<void> sendAudio(File file) async {
    _uploadAndSend(file: file, type: MessageType.audio);
  }

  Future<void> sendLocation(double lat, double long) async {
    _send(content: "$lat,$long", type: MessageType.location);
  }

  Future<void> _send({
    required String content,
    required MessageType type,
  }) async {
    _isSending = true;
    userActivityDetected();

    final tempId = const Uuid().v4();
    final tempMessage = MessageModel(
      id: tempId,
      senderId: _currentUserId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
    );

    // Add to list (at top)
    _messages.insert(0, tempMessage);
    notifyListeners();

    int? bookingIdInt;
    if (_bookingId != null) {
      bookingIdInt = int.tryParse(_bookingId!);
    }

    Map<String, dynamic>? replyToData;
    if (_replyingTo != null) {
      replyToData = {
        'messageId': _replyingTo!.id,
        'senderId': _replyingTo!.senderId,
        'senderName': _replyingTo!.isMe ? _currentUserName : _otherUserName,
        'messagePreview': MessageModel.getSnippet(
          _replyingTo!.type,
          _replyingTo!.content,
        ),
        'messageType': _replyingTo!.type.name,
      };
    }

    final success = await _repository.sendMessage(
      receiverId: _otherUserId,
      content: content,
      type: type
          .name, // Enum name is likely lowercase in provider too? Check enum.
      bookingId: bookingIdInt,
      replyToId: _replyingTo?.id,
      replyToData: replyToData,
    );

    if (success) {
      setReplyingTo(null);
    }

    _updateMessageStatus(
      tempId,
      success ? MessageStatus.sent : MessageStatus.failed,
    );
    _isSending = false;
    notifyListeners();
    _fetchUpdates(); // Sync real ID
  }

  Future<void> _uploadAndSend({
    required File file,
    required MessageType type,
  }) async {
    _isSending = true;
    userActivityDetected();

    final tempId = const Uuid().v4();
    final tempMessage = MessageModel(
      id: tempId,
      senderId: _currentUserId,
      content: file.path, // Local path for immediate display
      type: type,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
      attachmentUrl: file.path,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final url = await _repository.uploadFile(file);

      int? bookingIdInt;
      if (_bookingId != null) {
        bookingIdInt = int.tryParse(_bookingId!);
      }

      final success = await _repository.sendMessage(
        receiverId: _otherUserId,
        content: url,
        type: type.name,
        bookingId: bookingIdInt,
      );

      _updateMessageStatus(
        tempId,
        success ? MessageStatus.sent : MessageStatus.failed,
      );
    } catch (e) {
      _updateMessageStatus(tempId, MessageStatus.failed);
    }

    _isSending = false;
    notifyListeners();
    _fetchUpdates();
  }

  void _updateMessageStatus(String tempId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == tempId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
    }
  }
}
