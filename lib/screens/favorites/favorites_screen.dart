import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';

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
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No favorites yet', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Books you favorite will show up here',
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
                    // TODO: navigate to Book Details screen once merged.
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
