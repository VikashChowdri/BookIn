import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../models/user_model.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'profile/profile_screen.dart';
import 'cart/cart_screen.dart';
import 'chat/chat_list_screen.dart';
import '../../data/services/chat_service.dart';
import '../../models/chat.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CartScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!didPop) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Icons.search_rounded : Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 ? Icons.shopping_bag : Icons.shopping_bag_outlined),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<List<ChatRoom>>(
                stream: user != null ? ChatService.instance.getUserChats() : const Stream.empty(),
                builder: (context, snapshot) {
                  final chats = snapshot.data ?? [];
                  int totalUnread = 0;
                  if (user != null) {
                    for (var chat in chats) {
                      totalUnread += chat.unreadCounts[user.uid] ?? 0;
                    }
                  }
                  final icon = Icon(_currentIndex == 3 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded);
                  if (totalUnread > 0) {
                    return Badge(
                      label: Text('$totalUnread'),
                      child: icon,
                    );
                  }
                  return icon;
                },
              ),
              label: 'Chat',
            ),

            BottomNavigationBarItem(
              icon: StreamBuilder<UserModel?>(
                stream: user != null ? DatabaseService.instance.getUserProfileStream(user.uid) : const Stream.empty(),
                builder: (context, snapshot) {
                  final profileUrl = snapshot.data?.profilePictureUrl;
                  final hasImage = profileUrl != null && profileUrl.isNotEmpty && !profileUrl.contains('unsplash');

                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentIndex == 4 ? theme.colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      backgroundImage: hasImage ? CachedNetworkImageProvider(profileUrl) : null,
                      child: !hasImage
                          ? Icon(Icons.person, size: 16, color: theme.colorScheme.primary)
                          : null,
                    ),
                  );
                },
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
