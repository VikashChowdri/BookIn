import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/database_service.dart';
import '../../models/chat.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<UserModel?>(
        stream: DatabaseService.instance.getUserProfileStream(AuthService.instance.currentUser?.uid ?? ''),
        builder: (context, userSnapshot) {
          final currentUserProfile = userSnapshot.data;
          final blockedUsers = currentUserProfile?.blockedUsers ?? [];

          return StreamBuilder<List<ChatRoom>>(
            stream: ChatService.instance.getUserChats(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allChats = snapshot.data!;
              
              // Filter out chats with blocked users or invalid participants
              final chats = allChats.where((chat) {
                final currentUserId = AuthService.instance.currentUser?.uid;
                final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                return otherUserId.isNotEmpty && !blockedUsers.contains(otherUserId);
              }).toList();

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No messages yet', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation from a user\'s profile or book details.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final currentUserId = AuthService.instance.currentUser?.uid;
                  final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                  final unreadCount = chat.unreadCounts[currentUserId] ?? 0;

                  return FutureBuilder<UserModel?>(
                    future: otherUserId.isNotEmpty ? DatabaseService.instance.getUserProfile(otherUserId) : Future.value(null),
                    builder: (context, userSnapshot) {
                      final otherUser = userSnapshot.data;
                      final hasImage = otherUser != null && 
                          otherUser.profilePictureUrl.isNotEmpty &&
                          !otherUser.profilePictureUrl.contains('unsplash');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: hasImage ? CachedNetworkImageProvider(otherUser.profilePictureUrl) : null,
                          onBackgroundImageError: hasImage ? (error, stack) {} : null,
                          child: !hasImage
                              ? Icon(Icons.person, color: theme.colorScheme.primary)
                              : null,
                        ),
                        title: Text(
                          otherUser?.publicName ?? 'User',
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          chat.lastMessage.isEmpty ? 'Started a chat' : chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0 ? theme.colorScheme.onSurface : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0 ? theme.colorScheme.primary : Colors.grey[500],
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          final targetUser = otherUser ?? UserModel(
                            id: otherUserId,
                            email: '',
                            username: 'User',
                            publicName: 'User',
                            profilePictureUrl: '',
                            createdAt: DateTime.now(),
                          );
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chatDetail,
                            arguments: {
                              'roomId': chat.id,
                              'otherUser': targetUser,
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays <= 0 && now.day == time.day) {
      // Today: 10:30 AM
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final ampm = time.hour >= 12 ? 'PM' : 'AM';
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } else if (diff.inDays < 7 && diff.inDays >= 0) {
      // Within week: Mon, Tue...
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      // Older: Oct 12
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[time.month - 1]} ${time.day}';
    }
  }
}
