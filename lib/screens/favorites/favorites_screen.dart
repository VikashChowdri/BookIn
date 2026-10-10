import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';
import '../../widgets/options_menu.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Book> favorites = FavoritesManager.instance.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: const [
          AppOptionsMenu(),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('Your wishlist is empty', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Books you add to your wishlist will show up here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final book = favorites[index];
                return BookCard(
                  book: book,
                  isFavorite: true,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookDetails,
                      arguments: book,
                    );
                  },
                  onFavoriteTap: () {
                    setState(() {
                      FavoritesManager.instance.toggleFavorite(book);
                    });
                  },
                );
              },
            ),
    );
  }
}
