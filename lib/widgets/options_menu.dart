import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/theme_controller.dart';
import '../routes/app_routes.dart';

enum MenuOption { theme, favorites, myBookings, incomingRequests, profile, about }

/// A reusable options menu button to be placed in the AppBar.
class AppOptionsMenu extends StatelessWidget {
  const AppOptionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuOption>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Options',
      onSelected: (option) {
        switch (option) {
          case MenuOption.theme:
            ThemeController.showThemeSelectionDialog(context);
            break;
          case MenuOption.favorites:
            Navigator.pushNamed(context, AppRoutes.favorites);
            break;
          case MenuOption.myBookings:
            Navigator.pushNamed(context, AppRoutes.myRentals);
            break;
          case MenuOption.incomingRequests:
            Navigator.pushNamed(context, AppRoutes.purchaseRequests);
            break;
          case MenuOption.profile:
            Navigator.pushNamed(context, AppRoutes.profile);
            break;
          case MenuOption.about:
            _showAboutDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MenuOption.theme,
          child: Row(
            children: [
              Icon(Icons.palette_outlined, size: 20),
              SizedBox(width: 12),
              Text('Change Theme'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MenuOption.favorites,
          child: Row(
            children: [
              Icon(Icons.favorite_border, size: 20),
              SizedBox(width: 12),
              Text('Favorites'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MenuOption.myBookings,
          child: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 20),
              SizedBox(width: 12),
              Text('My Bookings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MenuOption.incomingRequests,
          child: Row(
            children: [
              Icon(Icons.inbox_outlined, size: 20),
              SizedBox(width: 12),
              Text('Incoming Requests'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MenuOption.profile,
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: MenuOption.about,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 12),
              Text('About'),
            ],
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: 'v${AppConstants.appVersion}',
      applicationIcon: const Icon(
        Icons.menu_book_rounded,
        size: 40,
        color: Color(0xFF4F46E5),
      ),
      children: const [
        Text(
          'BookIn is a mobile book exchange platform for college students to buy, sell, and exchange course books easily.',
        ),
      ],
    );
  }
}
