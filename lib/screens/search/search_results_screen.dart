import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dummy_books.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';
import 'search_widgets.dart';
 
const List<String> _sortOptions = [
  'Recommended',
  'Newest',
  'Price: Low to High',
  'Price: High to Low',
];
 
/// Everything the user can pick in the filter sheet, in one small box.
class _Filters {
  String sortBy;
  String? category;
  String? department;
  RangeValues? price; // null = any price
  bool availableOnly;
 
  _Filters({
    this.sortBy = 'Recommended',
    this.category,
    this.department,
    this.price,
    this.availableOnly = false,
  });
 
  _Filters copy() => _Filters(
        sortBy: sortBy,
        category: category,
        department: department,
        price: price,
        availableOnly: availableOnly,
      );
 
  int get activeCount =>
      (category != null ? 1 : 0) +
      (department != null ? 1 : 0) +
      (price != null ? 1 : 0) +
      (availableOnly ? 1 : 0);
}
 
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
    this.sortBy = 'Recommended',
  });
 
  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}
 
class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _loading = true;
  late _Filters _f;
  late final TextEditingController _box;
 
  List<String> get _categories =>
      dummyBooks.map((b) => b.category).toSet().toList();
  List<String> get _departments =>
      dummyBooks.map((b) => b.department).toSet().toList();
 
  /// Highest price rounded up to the next 50, used for the price slider.
  double get _maxPrice {
    final top = dummyBooks.fold<double>(0, (m, b) => b.price > m ? b.price : m);
    final rounded = ((top / 50).ceil() * 50).toDouble();
    return rounded < 50 ? 50 : rounded;
  }
 
  @override
  void initState() {
    super.initState();
    _f = _Filters(
      sortBy: _sortOptions.contains(widget.sortBy)
          ? widget.sortBy
          : 'Recommended',
      category: widget.category,
      department: widget.department,
    );
    _box = TextEditingController(
      text: widget.query.isNotEmpty
          ? widget.query
          : (widget.category ?? widget.department ?? ''),
    );
    _load();
  }
 
  Future<void> _load() async {
    // Simulated loading — swap for a real Firestore query later.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _loading = false);
  }
 
  @override
  void dispose() {
    _box.dispose();
    super.dispose();
  }
 
  // ───────── filter + sort ─────────
  List<Book> _compute() {
    final q = widget.query.toLowerCase();
    final list = dummyBooks.where((b) {
      final okQuery = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.subject.toLowerCase().contains(q);
      final okCategory = _f.category == null || b.category == _f.category;
      final okDept = _f.department == null || b.department == _f.department;
      final okPrice = _f.price == null ||
          (b.price >= _f.price!.start && b.price <= _f.price!.end);
      final okAvail = !_f.availableOnly || b.available;
      return okQuery && okCategory && okDept && okPrice && okAvail;
    }).toList();
 
    switch (_f.sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        return list;
      case 'Price: High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        return list;
      case 'Newest':
        // No date field yet, so "last added" = last in the list.
        return list.reversed.toList();
      default: // Recommended
        list.sort((a, b) => relevanceScore(b, widget.query)
            .compareTo(relevanceScore(a, widget.query)));
        return list;
    }
  }
 
  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_Filters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        initial: _f,
        categories: _categories,
        departments: _departments,
        maxPrice: _maxPrice,
      ),
    );
    if (result != null) setState(() => _f = result);
  }
 
  void _onBookTap(Book book) {
    FavoritesManager.instance.addRecentlyViewed(book);
    Navigator.pushNamed(context, AppRoutes.bookDetails, arguments: book);
  }
 
  // ───────── screen ─────────
  @override
  Widget build(BuildContext context) {
    final results = _loading ? <Book>[] : _compute();
 
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SearchBox(
              controller: _box,
              readOnly: true,
              onBack: () => Navigator.pop(context),
              onTap: () => Navigator.pop(context), // tap box = edit search
              onSubmitted: (_) => Navigator.pop(context),
              trailing: IconButton(
                icon: const Icon(Icons.favorite_border),
                tooltip: 'Favorites',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.favorites),
              ),
            ),
            _countRow(results.length),
            _chipRow(),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? _skeletonGrid()
                  : results.isEmpty
                      ? _EmptyState(
                          canClear: _f.activeCount > 0,
                          onClear: () => setState(() => _f = _Filters()),
                        )
                      : _grid(results),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _countRow(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _loading ? 'Searching…' : '$count Books',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _f.activeCount > 0,
              label: Text('${_f.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }
 
  /// Row of chips under the count: Sort, Category, Department, Price.
  Widget _chipRow() {
    final p = _f.price;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          PillChip(
              label: _f.sortBy,
              selected: true,
              showArrow: true,
              onTap: _openFilters),
          const SizedBox(width: 8),
          PillChip(
              label: _f.category ?? 'Category',
              soft: _f.category == null,
              selected: _f.category != null,
              showArrow: true,
              onTap: _openFilters),
          const SizedBox(width: 8),
          PillChip(
              label: _f.department ?? 'Department',
              soft: _f.department == null,
              selected: _f.department != null,
              showArrow: true,
              onTap: _openFilters),
          const SizedBox(width: 8),
          PillChip(
              label: p == null
                  ? 'Price'
                  : '${AppConstants.defaultCurrencySymbol}${p.start.round()} - ${AppConstants.defaultCurrencySymbol}${p.end.round()}',
              soft: p == null,
              selected: p != null,
              showArrow: true,
              onTap: _openFilters),
        ],
      ),
    );
  }
 
  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.66,
  );
 
  Widget _grid(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: _gridDelegate,
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        return BookCard(
          book: book,
          isGridMode: true,
          isFavorite: FavoritesManager.instance.isFavorite(book),
          onTap: () => _onBookTap(book),
          onFavoriteTap: () => setState(
              () => FavoritesManager.instance.toggleFavorite(book)),
        );
      },
    );
  }
 
  /// Grey boxes shown while loading (like Savana's grey placeholders).
  Widget _skeletonGrid() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: _gridDelegate,
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
    );
  }
}
 
// ═════════════════════════ Filter bottom sheet ═════════════════════════
class _FilterSheet extends StatefulWidget {
  final _Filters initial;
  final List<String> categories;
  final List<String> departments;
  final double maxPrice;
 
  const _FilterSheet({
    required this.initial,
    required this.categories,
    required this.departments,
    required this.maxPrice,
  });
 
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}
 
class _FilterSheetState extends State<_FilterSheet> {
  late _Filters f = widget.initial.copy();
 
  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
 
  @override
  Widget build(BuildContext context) {
    final ink = inkColor(context);
    final range = f.price ?? RangeValues(0, widget.maxPrice);
    final cur = AppConstants.defaultCurrencySymbol;
 
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Sort'),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final s in _sortOptions)
                        PillChip(
                          label: s,
                          selected: f.sortBy == s,
                          onTap: () => setState(() => f.sortBy = s),
                        ),
                    ]),
                    _title('Category'),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final c in widget.categories)
                        PillChip(
                          label: c,
                          selected: f.category == c,
                          onTap: () => setState(
                              () => f.category = f.category == c ? null : c),
                        ),
                    ]),
                    _title('Department'),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final d in widget.departments)
                        PillChip(
                          label: d,
                          selected: f.department == d,
                          onTap: () => setState(() =>
                              f.department = f.department == d ? null : d),
                        ),
                    ]),
                    _title('Price'),
                    Text('$cur${range.start.round()} - $cur${range.end.round()}'),
                    RangeSlider(
                      values: range,
                      min: 0,
                      max: widget.maxPrice,
                      divisions: (widget.maxPrice / 10).round(),
                      activeColor: ink,
                      onChanged: (v) => setState(() {
                        // full range = "no price filter"
                        f.price = (v.start == 0 && v.end == widget.maxPrice)
                            ? null
                            : v;
                      }),
                    ),
                    _title('Availability'),
                    PillChip(
                      label: 'Available only',
                      selected: f.availableOnly,
                      onTap: () =>
                          setState(() => f.availableOnly = !f.availableOnly),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: lineColor(context)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => setState(() => f = _Filters()),
                      child: const Text('Clear all',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: onInkColor(context),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context, f),
                      child: const Text('View books',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ═════════════════════════ Empty state ═════════════════════════
class _EmptyState extends StatelessWidget {
  final bool canClear;
  final VoidCallback onClear;
  const _EmptyState({required this.canClear, required this.onClear});
 
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
          if (canClear) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ],
      ),
    );
  }
}
