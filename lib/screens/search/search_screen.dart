import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/database_service.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';
import 'search_widgets.dart';
 
/// One tappable chip under "You Might Want To Search".
class _Topic {
  final String label;
  final String? query;
  final String? category;
  final String? department;
  final bool hot;
  const _Topic(this.label,
      {this.query, this.category, this.department, this.hot = false});
}
 
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
 
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
 
class _SearchScreenState extends State<SearchScreen> {
  // "static" = the list is remembered even when you leave and come back.
  static final List<String> _recent = [];
 
  final TextEditingController _controller = TextEditingController();
  String get _text => _controller.text.trim();
  
  List<Book> _allBooks = [];
  List<_Topic> _cachedTopics = [];
  List<Book> _cachedTrending = [];
  List<Book> _cachedRecommended = [];
  StreamSubscription<List<Book>>? _booksSub;

  @override
  void initState() {
    super.initState();
    _booksSub = DatabaseService.instance.getBooksStream().listen((books) {
      if (mounted) {
        setState(() {
          _allBooks = books;
          _updateCachedData();
        });
      }
    });
  }

  void _updateCachedData() {
    // Cache Topics
    final counts = <String, int>{};
    for (final b in _allBooks) {
      for (final k in [b.subject, b.category, b.department]) {
        counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hotLabels = ranked.take(3).map((e) => e.key).toSet();
 
    final all = <_Topic>[
      for (final s in _allBooks.map((b) => b.subject).toSet())
        _Topic(s, query: s, hot: hotLabels.contains(s)),
      for (final c in _allBooks.map((b) => b.category).toSet())
        _Topic(c, category: c, hot: hotLabels.contains(c)),
      for (final d in _allBooks.map((b) => b.department).toSet())
        _Topic(d, department: d, hot: hotLabels.contains(d)),
    ];
    _cachedTopics = [...all.where((t) => t.hot), ...all.where((t) => !t.hot)];

    // Cache Trending
    _cachedTrending = _allBooks.where((b) => b.available).take(6).toList();

    // Cache Recommended
    final seenIds = FavoritesManager.instance.recentlyViewed.map((b) => b.id).toSet();
    final list = _allBooks.where((b) => !seenIds.contains(b.id)).toList()
      ..sort((a, b) => relevanceScore(b, '').compareTo(relevanceScore(a, '')));
    _cachedRecommended = list.take(6).toList();
  }
 
  // ───────── data ─────────
  List<Book> get _suggestions {
    final q = _text.toLowerCase();
    if (q.isEmpty) return [];
    return _allBooks
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q) ||
            b.subject.toLowerCase().contains(q))
        .take(AppConstants.maxSuggestions + 1)
        .toList();
  }
 
  // ───────── actions ─────────
  void _go({String query = '', String? category, String? department}) {
    final q = query.trim();
    if (q.isNotEmpty) {
      _recent.remove(q);
      _recent.insert(0, q);
      if (_recent.length > AppConstants.maxRecentSearches) _recent.removeLast();
    }
    Navigator.pushNamed(
      context,
      AppRoutes.searchResults,
      arguments: {
        'query': q,
        'category': category,
        'department': department,
        'sortBy': 'Recommended',
      },
    );
  }
 
  void _openBook(Book book) {
    FavoritesManager.instance.addRecentlyViewed(book);
    Navigator.pushNamed(context, AppRoutes.bookDetails, arguments: book)
        .then((_) {
      if (mounted) setState(() {}); // refresh "Recommended For You"
    });
  }
 
  @override
  void dispose() {
    _booksSub?.cancel();
    _controller.dispose();
    super.dispose();
  }
 
  // ───────── screen ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SearchBox(
              controller: _controller,
              autofocus: true,
              onBack: () => Navigator.pop(context),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => _go(query: v),
            ),
            Expanded(child: _text.isEmpty ? _homeView() : _suggestionView()),
          ],
        ),
      ),
    );
  }
 
  /// Shown while the search box is empty.
  Widget _homeView() {
    final hasHistory = FavoritesManager.instance.recentlyViewed.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (_recent.isNotEmpty) ...[
          SectionTitle(
            'Recent Searches',
            trailing: TextButton(
              onPressed: () => setState(_recent.clear),
              child: const Text('Clear'),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final r in _recent)
                PillChip(label: r, onTap: () => _go(query: r)),
            ],
          ),
        ],
        const SectionTitle('You Might Want To Search'),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final t in _cachedTopics)
              PillChip(
                label: t.label,
                hot: t.hot,
                onTap: () => _go(
                  query: t.query ?? '',
                  category: t.category,
                  department: t.department,
                ),
              ),
          ],
        ),
        if (hasHistory) _shelf('Recommended For You', _cachedRecommended),
        _shelf('Trending Now', _cachedTrending),
      ],
    );
  }
 
  /// A sideways-scrolling row of book cards.
  Widget _shelf(String title, List<Book> books) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final book = books[i];
              return SizedBox(
                width: 150,
                child: BookCard(
                  book: book,
                  isGridMode: true,
                  isFavorite: FavoritesManager.instance.isFavorite(book),
                  onTap: () => _openBook(book),
                  onFavoriteTap: () => setState(
                      () => FavoritesManager.instance.toggleFavorite(book)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
 
  /// Shown while the user is typing.
  Widget _suggestionView() {
    final items = _suggestions;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: Text('Search "$_text"'),
          onTap: () => _go(query: _text),
        ),
        for (final book in items)
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.author),
            trailing: const Icon(Icons.north_west, size: 18),
            onTap: () => _go(query: book.title),
          ),
      ],
    );
  }
}
