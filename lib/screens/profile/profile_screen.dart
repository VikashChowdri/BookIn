import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../review/reviews_list_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userModel;
  bool _isLoading = true;
  int _booksListed = 0;
  int _exchanges = 0;
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      final userModel = await DatabaseService.instance.getUserProfile(user.uid);
      final booksCount = await DatabaseService.instance.getUserBooksCount(user.uid);
      final exchangesCount = await DatabaseService.instance.getUserExchangesCount(user.uid);
      final ratingVal = await DatabaseService.instance.getAverageRating(user.uid, 'user');
      
      if (mounted) {
        setState(() {
          _userModel = userModel;
          _booksListed = booksCount;
          _exchanges = exchangesCount;
          _rating = ratingVal;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _userModel?.publicName ?? user?.displayName ?? 'BookIn User';
    final username = _userModel?.username ?? '';
    final email = _userModel?.email ?? user?.email ?? 'No email';
    final phone = _userModel?.phone ?? '';
    final bio = _userModel?.bio ?? '';
    final avatarUrl = _userModel?.profilePictureUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.editProfile, arguments: _userModel);
              _loadUser(); // Refresh after edit
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: avatarUrl.isNotEmpty && !avatarUrl.contains('unsplash')
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty || avatarUrl.contains('unsplash')
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (username.isNotEmpty)
              Text(
                '@$username',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('$_booksListed', 'Books Listed', theme),
                _buildStatColumn('$_exchanges', 'Exchanges', theme),
                _buildStatColumn(_rating > 0 ? _rating.toStringAsFixed(1) : 'N/A', 'Rating', theme),
              ],
            ),
            const SizedBox(height: 28),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('My Listed Books'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.myListings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Exchange History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () => _handleSignOut(context),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            if (user != null)
              ReviewsListWidget(
                targetId: user.uid,
                targetType: 'user',
                targetName: displayName,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  Widget _buildStatColumn(String count, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}