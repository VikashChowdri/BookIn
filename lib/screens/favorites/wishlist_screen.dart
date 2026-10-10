import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';
import '../../widgets/options_menu.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Book> wishlist = FavoritesManager.instance.wishlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: const [
          AppOptionsMenu(),
        ],
      ),
      body: wishlist.isEmpty
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
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final book = wishlist[index];
                return FadeSlideEntry(
                  index: index,
                  staggerDelay: const Duration(milliseconds: 40),
                  slideOffset: const Offset(0, 16),
                  child: BookCard(
                    book: book,
                    isWishlist: true,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookDetails,
                        arguments: book,
                      );
                    },
                    onWishlistTap: () {
                      setState(() {
                        FavoritesManager.instance.toggleWishlist(book);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
