import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/database_service.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/options_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  List<String> _getCategories(List<Book> books) {
    final cats = books.map((b) => b.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Book> _getFilteredBooks(List<Book> books) {
    if (_selectedCategory == 'All') return books;
    return books.where((b) => b.category == _selectedCategory).toList();
  }

  List<Book> _getFeaturedBooks(List<Book> books) =>
      books.where((b) => b.available).take(5).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded,
                color: theme.colorScheme.primary, size: 26),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allBooks = snapshot.data ?? [];
          final categories = _getCategories(allBooks);
          final featuredBooks = _getFeaturedBooks(allBooks);
          final filteredBooks = _getFilteredBooks(allBooks);

          // Reset selection if category is no longer valid after data updates
          if (!categories.contains(_selectedCategory)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCategory = 'All');
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ── Greeting Banner ──
                _buildGreetingBanner(theme, isDark),

                const SizedBox(height: 20),

                // ── Category Chips ──
                _buildSectionTitle(theme, 'Browse Categories'),
                const SizedBox(height: 8),
                _buildCategoryChips(theme, categories),

                const SizedBox(height: 24),

                // ── Featured Books Carousel ──
                _buildSectionTitle(
                  theme,
                  'Featured Books',
                  trailing: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.bookListing),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('View All'),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeaturedCarousel(theme, isDark, featuredBooks),

                const SizedBox(height: 24),

                // ── All Books Listing ──
                _buildSectionTitle(
                  theme,
                  _selectedCategory == 'All'
                      ? 'All Books'
                      : '$_selectedCategory Books',
                  trailing: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.bookListing,
                      arguments: {
                        'category': _selectedCategory == 'All'
                            ? null
                            : _selectedCategory,
                      },
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('View All'),
                  ),
                ),
                const SizedBox(height: 8),
                _buildBookList(theme, isDark, filteredBooks),

                const SizedBox(height: 80), // space for FAB
              ],
            ),
          );
        }
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

  Widget _buildGreetingBanner(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.primaryDark, const Color(0xFF1E1B4B)]
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Student! 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.appTagline,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add Book',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.addBook),
              ),
              const SizedBox(width: 12),
              _bannerActionButton(
                icon: Icons.list_alt_rounded,
                label: 'My Listings',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.myListings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, List<String> categories) {
    if (categories.isEmpty || (categories.length == 1 && categories.first == 'All')) {
      return const SizedBox(height: 0);
    }
    
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final selected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            selectedColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusCircular),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel(ThemeData theme, bool isDark, List<Book> books) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No featured books available.'),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildFeaturedCard(book, theme, isDark);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(Book book, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        FavoritesManager.instance.addRecentlyViewed(book);
        Navigator.pushNamed(context, AppRoutes.bookDetails, arguments: book);
      },
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusMedium),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.shimmerBase,
                child: Image.network(
                  book.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppConstants.defaultCurrencySymbol}${book.price.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        _availabilityChip(book.available, small: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(ThemeData theme, bool isDark, List<Book> books) {
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.auto_stories_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No books in this category yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookListTile(book, theme, isDark);
      },
    );
  }

  Widget _buildBookListTile(Book book, ThemeData theme, bool isDark) {
    final isFav = FavoritesManager.instance.isFavorite(book);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          onTap: () {
            FavoritesManager.instance.addRecentlyViewed(book);
            Navigator.pushNamed(context, AppRoutes.bookDetails,
                arguments: book);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  child: Container(
                    width: 64,
                    height: 80,
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.shimmerBase,
                    child: Image.network(
                      book.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.menu_book,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${book.author} · ${book.subject}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${AppConstants.defaultCurrencySymbol}${book.price.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _availabilityChip(book.available),
                          const Spacer(),
                          Text(
                            book.sellerName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Favorite button
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppColors.error : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      FavoritesManager.instance.toggleFavorite(book);
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _availabilityChip(bool available, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: available
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusCircular),
      ),
      child: Text(
        available ? 'Available' : 'Sold',
        style: TextStyle(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w600,
          color: available ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
