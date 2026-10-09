import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final userId = AuthService.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Listings')),
        body: const Center(child: Text('Please log in to view listings')),
      );
    }

    return StreamBuilder<List<Book>>(
      stream: DatabaseService.instance.getUserBooksStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Listings')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Listings')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final allBooks = snapshot.data ?? [];
        final availableBooks = allBooks.where((b) => b.available).toList();
        final soldBooks = allBooks.where((b) => !b.available).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Listings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add Book',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addBook);
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'All (${allBooks.length})'),
                Tab(text: 'Available (${availableBooks.length})'),
                Tab(text: 'Sold (${soldBooks.length})'),
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
              _buildBookList(allBooks, theme, isDark),
              _buildBookList(availableBooks, theme, isDark),
              _buildBookList(soldBooks, theme, isDark),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addBook);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Book'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        );
      }
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
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.bookDetails,
              arguments: book,
            );
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
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.getBookCover(book.imageUrl, book.id),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Center(
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.error),
                          SizedBox(width: 10),
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
        Navigator.pushNamed(
          context,
          AppRoutes.bookDetails,
          arguments: book,
        );
        break;

      case 'edit':
        Navigator.pushNamed(
          context,
          AppRoutes.editBook,
          arguments: book,
        );
        break;

      case 'toggle':
        try {
          final updatedBook = book.copyWith(available: !book.available);
          await DatabaseService.instance.updateBook(updatedBook);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  updatedBook.available
                      ? '"${book.title}" marked as Available'
                      : '"${book.title}" marked as Sold',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: $e')),
            );
          }
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
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog first
              
              try {
                await DatabaseService.instance.deleteBook(book.id);
                
                if (FavoritesManager.instance.isFavorite(book)) {
                  FavoritesManager.instance.toggleFavorite(book);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${book.title}" deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete book: $e')),
                  );
                }
              }
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
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addBook);
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
