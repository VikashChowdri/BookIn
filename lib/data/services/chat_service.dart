import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import 'auth_service.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // ensures that userId1 and userId2 always produce the same id
    return ids.join('_');
  }

  Future<String> getOrCreateChatRoom(String otherUserId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not logged in');
    if (currentUserId == otherUserId) throw Exception('Cannot chat with yourself');

    final roomId = _getChatRoomId(currentUserId, otherUserId);
    final roomDoc = _firestore.collection('chats').doc(roomId);

    final snapshot = await roomDoc.get();
    if (!snapshot.exists) {
      await roomDoc.set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'typing': [],
      });
    }

    return roomId;
  }

  Stream<List<ChatRoom>> getUserChats() {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    // Query by arrayContains without orderBy to avoid requiring a composite index.
    // We sort the results in memory by lastMessageTime descending.
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.id, doc.data()))
          .toList();
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  Stream<List<Message>> getChatMessages(String roomId) {
    // Sort in memory to avoid index requirements and latency compensation null-timestamp jumps
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage(
    String roomId,
    String otherUserId,
    String text, {
    String? attachedBookId,
    String? attachedBookTitle,
    String? attachedBookImageUrl,
    String? chatImageUrl,
  }) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null || (text.trim().isEmpty && attachedBookId == null && chatImageUrl == null)) return;

    final roomDoc = _firestore.collection('chats').doc(roomId);

    // Add message with isRead: false
    await roomDoc.collection('messages').add({
      'senderId': currentUserId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      if (attachedBookId != null) 'attachedBookId': attachedBookId,
      if (attachedBookTitle != null) 'attachedBookTitle': attachedBookTitle,
      if (attachedBookImageUrl != null) 'attachedBookImageUrl': attachedBookImageUrl,
      if (chatImageUrl != null) 'chatImageUrl': chatImageUrl,
    });

    String lastMsgText = text.trim();
    if (chatImageUrl != null && text.trim().isEmpty) {
      lastMsgText = 'Sent an image 📸';
    } else if (attachedBookTitle != null) {
      lastMsgText = 'Shared a book: $attachedBookTitle';
    }

    // Update room safely with SetOptions(merge: true)
    await roomDoc.set({
      'participants': [currentUserId, otherUserId],
      'lastMessage': lastMsgText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {
        otherUserId: FieldValue.increment(1),
        currentUserId: 0,
      },
    }, SetOptions(merge: true));

    // Send in-app notification to receiver
    try {
      final currentUserName = AuthService.instance.currentUser?.displayName ?? 'Someone';
      final notifRef = _firestore.collection('notifications').doc();
      await notifRef.set({
        'userId': otherUserId,
        'title': 'New Message from $currentUserName',
        'body': lastMsgText,
        'type': 'chat_message',
        'relatedId': roomId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> markAsRead(String roomId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final roomDoc = _firestore.collection('chats').doc(roomId);
      await roomDoc.set({
        'unreadCounts': {
          currentUserId: 0,
        },
      }, SetOptions(merge: true));

      // Mark messages as read using single-field query to avoid missing composite index
      final unreadMessages = await roomDoc
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;
      for (var doc in unreadMessages.docs) {
        final data = doc.data();
        if (data['senderId'] != currentUserId) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
          hasUpdates = true;
        }
      }
      if (hasUpdates) {
        await batch.commit();
      }
    } catch (_) {
      // Don't crash if offline or indexing issues
    }
  }

  Future<void> updateTypingStatus(String roomId, bool isTyping) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final roomDoc = _firestore.collection('chats').doc(roomId);
      if (isTyping) {
        await roomDoc.set({
          'typing': FieldValue.arrayUnion([currentUserId])
        }, SetOptions(merge: true));
      } else {
        await roomDoc.set({
          'typing': FieldValue.arrayRemove([currentUserId])
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Stream<ChatRoom?> getChatRoomStream(String roomId) {
    return _firestore.collection('chats').doc(roomId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return ChatRoom.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final roomDoc = _firestore.collection('chats').doc(roomId);
      await roomDoc.collection('messages').doc(messageId).delete();

      // Update room's lastMessage by checking remaining messages
      final remainingSnapshot = await roomDoc.collection('messages').get();
      if (remainingSnapshot.docs.isNotEmpty) {
        final remaining = remainingSnapshot.docs
            .map((doc) => Message.fromMap(doc.id, doc.data()))
            .toList();
        remaining.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final latest = remaining.first;

        String latestText = latest.text;
        if (latestText.isEmpty) {
          if (latest.chatImageUrl != null) {
            latestText = 'Sent an image 📸';
          } else if (latest.attachedBookTitle != null) {
            latestText = 'Shared a book: ${latest.attachedBookTitle}';
          }
        }

        await roomDoc.set({
          'lastMessage': latestText,
          'lastMessageTime': Timestamp.fromDate(latest.timestamp),
        }, SetOptions(merge: true));
      } else {
        await roomDoc.set({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
