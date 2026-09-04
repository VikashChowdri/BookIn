import 'package:flutter/material.dart';
import '../../data/dummy_books.dart';
import '../../models/book.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? category;
  final String? department;
  final String sortBy;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.category,
    this.department,
    this.sortBy = 'Newest',
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _loading = true;
  List<Book> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    // Simulated loading state — swap for a real Firestore query in a later review.
    await Future.delayed(const Duration(milliseconds: 400));

    var results = dummyBooks.where((book) {
      final query = widget.query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.subject.toLowerCase().contains(query);
      final matchesCategory =
          widget.category == null || book.category == widget.category;
      final matchesDepartment =
          widget.department == null || book.department == widget.department;
      return matchesQuery && matchesCategory && matchesDepartment;
    }).toList();

    if (widget.sortBy == 'Price: Low to High') {
      results.sort((a, b) => a.price.compareTo(b.price));
    } else if (widget.sortBy == 'Price: High to Low') {
      results.sort((a, b) => b.price.compareTo(a.price));
    }

    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _onBookTap(Book book) {
    FavoritesManager.instance.addRecentlyViewed(book);
    // TODO: navigate to Book Details screen once merged (Member 2's module).
    // Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results for "${widget.query}"')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final book = _results[index];
                    return BookCard(
                      book: book,
                      isFavorite: FavoritesManager.instance.isFavorite(book),
                      onTap: () => _onBookTap(book),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('No books found', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Try a different search or clear your filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
