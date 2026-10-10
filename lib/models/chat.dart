import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final List<String> typing;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    this.typing = const [],
  });

  factory ChatRoom.fromMap(String id, Map<String, dynamic> data) {
    Map<String, int> counts = {};
    if (data['unreadCounts'] is Map) {
      (data['unreadCounts'] as Map).forEach((k, v) {
        counts[k.toString()] = (v is num) ? v.toInt() : 0;
      });
    }

    return ChatRoom(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: counts,
      typing: List<String>.from(data['typing'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'typing': typing,
    };
  }
}
