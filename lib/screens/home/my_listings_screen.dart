import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dummy_books.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // In a real app, filter by logged-in user. For now, show all books.
  List<Book> get _allListings => dummyBooks;

  List<Book> get _availableListings =>
      _allListings.where((b) => b.available).toList();

  List<Book> get _soldListings =>
      _allListings.where((b) => !b.available).toList();


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Book',
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.addBook);
              setState(() {}); // Refresh after adding
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_allListings.length})'),
            Tab(text: 'Available (${_availableListings.length})'),
            Tab(text: 'Sold (${_soldListings.length})'),
          ],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookList(_allListings, theme, isDark),
          _buildBookList(_availableListings, theme, isDark),
          _buildBookList(_soldListings, theme, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addBook);
          setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBookList(
      List<Book> books, ThemeData theme, bool isDark) {
    if (books.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildListingTile(book, theme, isDark);
      },
    );
  }

  Widget _buildListingTile(Book book, ThemeData theme, bool isDark) {
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
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.bookDetails,
              arguments: book,
            );
            setState(() {}); // Refresh in case book was deleted/edited
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
                    width: 60,
                    height: 76,
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
                        book.author,
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
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Action buttons
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (action) =>
                      _handleAction(action, book, theme),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Toggle Availability'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text('Delete',
                              style:
                                  TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(String action, Book book, ThemeData theme) async {
    switch (action) {
      case 'view':
        await Navigator.pushNamed(
          context,
          AppRoutes.bookDetails,
          arguments: book,
        );
        setState(() {});
        break;

      case 'edit':
        await Navigator.pushNamed(
          context,
          AppRoutes.editBook,
          arguments: book,
        );
        setState(() {});
        break;

      case 'toggle':
        final index = dummyBooks.indexWhere((b) => b.id == book.id);
        if (index != -1) {
          dummyBooks[index] = Book(
            id: book.id,
            title: book.title,
            author: book.author,
            subject: book.subject,
            category: book.category,
            department: book.department,
            imageUrl: book.imageUrl,
            description: book.description,
            sellerName: book.sellerName,
            sellerId: book.sellerId,
            available: !book.available,
            price: book.price,
          );
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                book.available
                    ? '"${book.title}" marked as Sold'
                    : '"${book.title}" marked as Available',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case 'delete':
        _showDeleteDialog(book, theme);
        break;
    }
  }

  void _showDeleteDialog(Book book, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: AppColors.error,
            size: 32,
          ),
        ),
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"?\nThis action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final removedIndex =
                  dummyBooks.indexWhere((b) => b.id == book.id);
              if (removedIndex != -1) {
                dummyBooks.removeAt(removedIndex);
              }
              if (FavoritesManager.instance.isFavorite(book)) {
                FavoritesManager.instance.toggleFavorite(book);
              }

              Navigator.pop(dialogContext);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${book.title}" deleted'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      if (removedIndex != -1 &&
                          removedIndex <= dummyBooks.length) {
                        dummyBooks.insert(removedIndex, book);
                      } else {
                        dummyBooks.add(book);
                      }
                      setState(() {});
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No listings yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start selling by adding your first book!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.addBook);
                setState(() {});
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Your First Book'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityChip(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: available
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusCircular),
      ),
      child: Text(
        available ? 'Available' : 'Sold',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: available ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
