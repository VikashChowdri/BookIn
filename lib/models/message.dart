import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? attachedBookId;
  final String? attachedBookTitle;
  final String? attachedBookImageUrl;
  final String? chatImageUrl;
  final bool isRead;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.attachedBookId,
    this.attachedBookTitle,
    this.attachedBookImageUrl,
    this.chatImageUrl,
    this.isRead = false,
    this.readAt,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachedBookId: data['attachedBookId'],
      attachedBookTitle: data['attachedBookTitle'],
      attachedBookImageUrl: data['attachedBookImageUrl'],
      chatImageUrl: data['chatImageUrl'],
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      if (attachedBookId != null) 'attachedBookId': attachedBookId,
      if (attachedBookTitle != null) 'attachedBookTitle': attachedBookTitle,
      if (attachedBookImageUrl != null) 'attachedBookImageUrl': attachedBookImageUrl,
      if (chatImageUrl != null) 'chatImageUrl': chatImageUrl,
      'isRead': isRead,
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    };
  }
}
