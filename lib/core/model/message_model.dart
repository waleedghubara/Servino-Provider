import 'package:easy_localization/easy_localization.dart';

enum MessageType { text, image, video, audio, location }

enum MessageStatus { sending, sent, delivered, read, failed }

class MessageModel {
  final String id;
  final String senderId;
  final String content; // Text message or URL for media
  final MessageType type;
  final DateTime timestamp;
  final bool isMe;
  final String? duration; // For audio/video duration
  final String? videoThumbnail; // For video thumbnail
  final String? attachmentUrl; // For local files or additional media
  final String? senderImage; // For dynamic avatar
  final String? senderName; // For dynamic name
  final MessageStatus status;
  final String? replyToId;
  final ReplyModel? replyTo;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isMe,
    this.duration,
    this.videoThumbnail,
    this.attachmentUrl,
    this.senderImage,
    this.senderName,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.replyTo,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content'] ?? '',
      type: parseType(json['type'], json['content']),
      timestamp: DateTime.parse(json['timestamp']),
      isMe: json['is_me'] ?? false,
      duration: json['duration'],
      videoThumbnail: json['video_thumbnail'],
      attachmentUrl: json['type'] != 'text' ? json['content'] : null,
      senderImage: json['sender_image'],
      senderName: json['sender_name'],
      status: _parseStatus(json['status']?.toString()),
      replyToId: json['reply_to_id']?.toString(),
      replyTo: json['reply_to_data'] != null
          ? ReplyModel.fromJson(
              Map<String, dynamic>.from(json['reply_to_data']),
            )
          : null,
    );
  }

  static MessageStatus _parseStatus(String? status) {
    if (status == null) return MessageStatus.sent;

    switch (status.toLowerCase()) {
      case 'read':
      case 'seen':
      case '2': // Access 'read' as 2
        return MessageStatus.read;
      case 'delivered':
      case '1': // Access 'delivered' as 1
        return MessageStatus.delivered;
      case 'sent':
      case '0': // Access 'sent' as 0
        return MessageStatus.sent;
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
      case 'error':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  static MessageType parseType(String? type, [String? content]) {
    MessageType t;
    switch (type) {
      case 'image':
        t = MessageType.image;
        break;
      case 'video':
        t = MessageType.video;
        break;
      case 'audio':
        t = MessageType.audio;
        break;
      case 'location':
        t = MessageType.location;
        break;
      default:
        t = MessageType.text;
    }

    // Inference from content if type is text
    if (t == MessageType.text && content != null) {
      if (content.contains('google.com/maps') ||
          content.contains('openstreetmap.org')) {
        return MessageType.location;
      }
      if (content.endsWith('.m4a') ||
          content.endsWith('.mp3') ||
          content.endsWith('.wav')) {
        return MessageType.audio;
      }
      if (content.endsWith('.jpg') ||
          content.endsWith('.jpeg') ||
          content.endsWith('.png')) {
        return MessageType.image;
      }
      if (content.endsWith('.mp4') || content.endsWith('.mov')) {
        return MessageType.video;
      }
    }
    return t;
  }

  static String getSnippet(MessageType type, String content) {
    // If it's text but looks like a known media/location, infer it
    if (type == MessageType.text) {
      if (content.contains('google.com/maps') ||
          content.contains('openstreetmap.org')) {
        return 'type_location'.tr();
      }
      if (content.endsWith('.m4a') ||
          content.endsWith('.mp3') ||
          content.endsWith('.wav')) {
        return 'type_voice'.tr();
      }
      if (content.endsWith('.jpg') ||
          content.endsWith('.jpeg') ||
          content.endsWith('.png')) {
        return 'type_photo'.tr();
      }
      if (content.endsWith('.mp4') || content.endsWith('.mov')) {
        return 'type_video'.tr();
      }
    }

    switch (type) {
      case MessageType.image:
        return 'type_photo'.tr();
      case MessageType.video:
        return 'type_video'.tr();
      case MessageType.audio:
        return 'type_voice'.tr();
      case MessageType.location:
        return 'type_location'.tr();
      default:
        return content;
    }
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isMe,
    String? duration,
    String? videoThumbnail,
    String? attachmentUrl,
    String? senderImage,
    String? senderName,
    MessageStatus? status,
    String? replyToId,
    ReplyModel? replyTo,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      duration: duration ?? this.duration,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      senderImage: senderImage ?? this.senderImage,
      senderName: senderName ?? this.senderName,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'content': content,
      'type': type.name, // Assuming enum has name
      'timestamp': timestamp.toIso8601String(),
      'is_me': isMe,
      'duration': duration,
      'video_thumbnail': videoThumbnail,
      'sender_image': senderImage,
      'sender_name': senderName,
      'status': status.name, // Assuming enum has name
      'reply_to_id': replyToId,
      'reply_to_data': replyTo?.toJson(),
    };
  }
}

class ReplyModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String messagePreview;
  final MessageType messageType;

  ReplyModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.messagePreview,
    required this.messageType,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    return ReplyModel(
      messageId: json['messageId'].toString(),
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? '',
      messagePreview: json['messagePreview'] ?? '',
      messageType: MessageModel.parseType(json['messageType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'messagePreview': messagePreview,
      'messageType': messageType.name,
    };
  }

  static MessageType parseType(String? type, [String? content]) {
    MessageType t;
    switch (type) {
      case 'image':
        t = MessageType.image;
        break;
      case 'video':
        t = MessageType.video;
        break;
      case 'audio':
        t = MessageType.audio;
        break;
      case 'location':
        t = MessageType.location;
        break;
      default:
        t = MessageType.text;
    }

    // Inference from content if type is text
    if (t == MessageType.text && content != null) {
      if (content.contains('google.com/maps') ||
          content.contains('openstreetmap.org')) {
        return MessageType.location;
      }
      if (content.endsWith('.m4a') ||
          content.endsWith('.mp3') ||
          content.endsWith('.wav')) {
        return MessageType.audio;
      }
      if (content.endsWith('.jpg') ||
          content.endsWith('.jpeg') ||
          content.endsWith('.png')) {
        return MessageType.image;
      }
      if (content.endsWith('.mp4') || content.endsWith('.mov')) {
        return MessageType.video;
      }
    }
    return t;
  }
}
