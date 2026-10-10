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

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Message>> getChatMessages(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> sendMessage(String roomId, String otherUserId, String text, {String? attachedBookId, String? attachedBookTitle, String? attachedBookImageUrl, String? chatImageUrl}) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null || (text.trim().isEmpty && attachedBookId == null && chatImageUrl == null)) return;

    final roomDoc = _firestore.collection('chats').doc(roomId);
    
    // Add message
    await roomDoc.collection('messages').add({
      'senderId': currentUserId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
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

    // Update room
    await roomDoc.update({
      'lastMessage': lastMsgText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    });
  }

  Future<void> markAsRead(String roomId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final roomDoc = _firestore.collection('chats').doc(roomId);
    await roomDoc.update({
      'unreadCounts.$currentUserId': 0,
    });

    // Mark messages as read
    final unreadMessages = await roomDoc.collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateTypingStatus(String roomId, bool isTyping) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final roomDoc = _firestore.collection('chats').doc(roomId);
    if (isTyping) {
      await roomDoc.update({
        'typing': FieldValue.arrayUnion([currentUserId])
      });
    } else {
      await roomDoc.update({
        'typing': FieldValue.arrayRemove([currentUserId])
      });
    }
  }

  Stream<ChatRoom?> getChatRoomStream(String roomId) {
    return _firestore.collection('chats').doc(roomId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return ChatRoom.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }
}
