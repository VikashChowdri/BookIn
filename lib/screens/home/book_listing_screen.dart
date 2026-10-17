import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/database_service.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';
import '../../widgets/options_menu.dart';

class BookListingScreen extends StatefulWidget {
  final String? initialCategory;

  const BookListingScreen({super.key, this.initialCategory});

  @override
  State<BookListingScreen> createState() => _BookListingScreenState();
}

class _BookListingScreenState extends State<BookListingScreen> {
  late String _selectedCategory;
  String? _selectedDepartment;
  String _sortBy = 'Newest';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  List<String> _getCategories(List<Book> books) {
    final cats = books
        .map((b) => b.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  List<String> _getDepartments(List<Book> books) {
    final deps = books
        .map((b) => b.department.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...deps];
  }

  List<Book> _getFilteredBooks(List<Book> books) {
    var result = List<Book>.from(books);

    // Category filter
    if (_selectedCategory != 'All') {
      result = result.where((b) => b.category == _selectedCategory).toList();
    }

    // Department filter
    if (_selectedDepartment != null && _selectedDepartment != 'All') {
      result = result.where((b) => b.department == _selectedDepartment).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Price: Low to High':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Title A-Z':
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Newest':
      default:
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Books'),
        actions: [
          IconButton(
            icon: Icon(_isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          const AppOptionsMenu(),
        ],
      ),
      body: StreamBuilder<List<Book>>(
        stream: DatabaseService.instance.getBooksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allBooks = snapshot.data ?? [];
          final categories = _getCategories(allBooks);
          final departments = _getDepartments(allBooks);
          final books = _getFilteredBooks(allBooks);

          // Reset invalid selections after data loads
          if (!categories.contains(_selectedCategory)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCategory = 'All');
            });
          }

          return Column(
            children: [
              _buildFilterBar(theme, isDark, categories, departments),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${books.length} book${books.length == 1 ? '' : 's'} found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_selectedCategory != 'All' ||
                        (_selectedDepartment != null &&
                            _selectedDepartment != 'All'))
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _selectedCategory = 'All';
                          _selectedDepartment = null;
                        }),
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Clear filters'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: books.isEmpty
                    ? _buildEmptyState(theme)
                    : _isGridView
                        ? _buildGridView(books, theme)
                        : _buildListView(books, theme),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addBook),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─────────────────────────── Filter Bar ─────────────────────────────────

  Widget _buildFilterBar(ThemeData theme, bool isDark, List<String> categories, List<String> departments) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircular),
                  ),
                );
              },
            ),
          ),

          // Department + Sort row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Department dropdown
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusSmall),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment ?? 'All',
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        items: departments
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedDepartment =
                              v == 'All' ? null : v;
                        }),
                        hint: const Text('Department'),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Sort dropdown
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusSmall),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Newest', child: Text('Newest')),
                          DropdownMenuItem(
                              value: 'Price: Low to High',
                              child: Text('Price: Low → High')),
                          DropdownMenuItem(
                              value: 'Price: High to Low',
                              child: Text('Price: High → Low')),
                          DropdownMenuItem(
                              value: 'Title A-Z',
                              child: Text('Title A-Z')),
                        ],
                        onChanged: (v) =>
                            setState(() => _sortBy = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─────────────────────────── Grid View ──────────────────────────────────

  Widget _buildGridView(List<Book> books, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          isGridMode: true,
          isWishlist: FavoritesManager.instance.isWishlist(book),
          onTap: () {
            FavoritesManager.instance.addRecentlyViewed(book);
            Navigator.pushNamed(context, AppRoutes.bookDetails,
                arguments: book);
          },
          onWishlistTap: () {
            setState(() {
              FavoritesManager.instance.toggleWishlist(book);
            });
          },
        );
      },
    );
  }

  // ─────────────────────────── List View ──────────────────────────────────

  Widget _buildListView(List<Book> books, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          isGridMode: false,
          isWishlist: FavoritesManager.instance.isWishlist(book),
          onTap: () {
            FavoritesManager.instance.addRecentlyViewed(book);
            Navigator.pushNamed(context, AppRoutes.bookDetails,
                arguments: book);
          },
          onWishlistTap: () {
            setState(() {
              FavoritesManager.instance.toggleWishlist(book);
            });
          },
        );
      },
    );
  }

  // ─────────────────────────── Empty State ────────────────────────────────

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No books found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or add a new book.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedCategory = 'All';
                _selectedDepartment = null;
                _sortBy = 'Newest';
              }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filters'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 42),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
