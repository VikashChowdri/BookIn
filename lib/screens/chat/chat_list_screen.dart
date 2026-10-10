import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/database_service.dart';
import '../../models/chat.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, UserModel> _userCache = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<UserModel?>(
        stream: DatabaseService.instance.getUserProfileStream(currentUserId),
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
              final validChats = allChats.where((chat) {
                final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                return otherUserId.isNotEmpty && !blockedUsers.contains(otherUserId);
              }).toList();

              // Prefetch profiles for search if not cached yet
              for (var chat in validChats) {
                final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                if (otherUserId.isNotEmpty && !_userCache.containsKey(otherUserId)) {
                  DatabaseService.instance.getUserProfile(otherUserId).then((u) {
                    if (u != null && mounted) {
                      setState(() {
                        _userCache[otherUserId] = u;
                      });
                    }
                  });
                }
              }

              // Apply search filter
              final chats = validChats.where((chat) {
                if (_searchQuery.isEmpty) return true;
                final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                final user = _userCache[otherUserId];
                final matchName = user != null && (
                  user.publicName.toLowerCase().contains(_searchQuery) ||
                  user.username.toLowerCase().contains(_searchQuery)
                );
                final matchMsg = chat.lastMessage.toLowerCase().contains(_searchQuery);
                return matchName || matchMsg;
              }).toList();

              if (validChats.isEmpty) {
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

              return Column(
                children: [
                  // Modern search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search chats or messages...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),

                  // Search empty state or chat list
                  Expanded(
                    child: chats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No conversations matching "$_searchQuery"',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: chats.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                              final unreadCount = chat.unreadCounts[currentUserId] ?? 0;

                              return FutureBuilder<UserModel?>(
                                future: otherUserId.isNotEmpty
                                    ? (_userCache.containsKey(otherUserId)
                                        ? Future.value(_userCache[otherUserId])
                                        : DatabaseService.instance.getUserProfile(otherUserId))
                                    : Future.value(null),
                                builder: (context, userSnapshot) {
                                  final otherUser = userSnapshot.data ?? _userCache[otherUserId];
                                  if (otherUser != null && !_userCache.containsKey(otherUserId)) {
                                    _userCache[otherUserId] = otherUser;
                                  }

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
                          ),
                  ),
                ],
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
