import 'package:flutter/material.dart';
import '../models/book.dart';
import '../core/utils/globals.dart';

/// Simple in-memory favorites + recently-viewed tracker for Review 1.
/// No Firebase/provider layer yet — swap the internals for a
/// Firestore-backed service in a later review without changing callers.
class FavoritesManager {
  FavoritesManager._();
  static final FavoritesManager instance = FavoritesManager._();

  final List<Book> _favorites = [];
  final List<Book> _recentlyViewed = [];

  List<Book> get favorites => List.unmodifiable(_favorites);
  List<Book> get recentlyViewed => List.unmodifiable(_recentlyViewed);

  bool isFavorite(Book book) => _favorites.any((b) => b.id == book.id);

  void toggleFavorite(Book book) {
    final bool isFav;
    if (isFavorite(book)) {
      _favorites.removeWhere((b) => b.id == book.id);
      isFav = false;
    } else {
      _favorites.add(book);
      isFav = true;
    }

    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(isFav ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void addRecentlyViewed(Book book) {
    _recentlyViewed.removeWhere((b) => b.id == book.id);
    _recentlyViewed.insert(0, book);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed.removeLast();
    }
  }
}
