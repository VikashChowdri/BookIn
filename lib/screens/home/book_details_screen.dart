import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../booking/booking_dialog.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dummy_books.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';
import '../../utils/favorites_manager.dart';
import '../review/reviews_list_widget.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  Book get book => widget.book;

  bool get _isFavorite => FavoritesManager.instance.isFavorite(book);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOwner = book.sellerId == AuthService.instance.currentUser?.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsing App Bar with Book Cover ──
          _buildSliverAppBar(theme, isDark),

          // ── Body Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Author
                  _buildTitleSection(theme),

                  const SizedBox(height: 16),

                  // Price, Availability, Department row
                  _buildInfoChips(theme, isDark),

                  const SizedBox(height: 24),

                  // Quick stats row
                  _buildStatsRow(theme, isDark),

                  const SizedBox(height: 24),

                  // Description
                  _buildDescriptionSection(theme),

                  const SizedBox(height: 24),

                  // Seller Info
                  _buildSellerSection(theme, isDark),

                  if (isOwner) ...[
                    const SizedBox(height: 24),
                    // Action Buttons
                    _buildActionButtons(theme),
                  ],

                  const SizedBox(height: 24),

                  // Reviews
                  ReviewsListWidget(
                    targetId: book.id,
                    targetType: 'book',
                    targetName: book.title,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Bar ──
      bottomNavigationBar: isOwner ? null : _buildBottomBar(theme, isDark),
    );
  }

  // ─────────────────────────── Sliver AppBar ──────────────────────────────

  SliverAppBar _buildSliverAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            child: IconButton(
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? AppColors.error : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  FavoritesManager.instance.toggleFavorite(book);
                });
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Book cover image
            CachedNetworkImage(
              imageUrl: AppConstants.getBookCover(book.imageUrl, book.id),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? AppColors.darkBackground : AppColors.shimmerBase,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? AppColors.darkBackground : AppColors.shimmerBase,
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            // Gradient overlay for readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            // Availability badge on cover
            Positioned(
              bottom: 16,
              left: 20,
              child: _availabilityBadge(book.available, book.status),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Title Section ──────────────────────────────

  Widget _buildTitleSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.person_outline_rounded,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                book.author,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────── Info Chips ──────────────────────────────────

  Widget _buildInfoChips(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Price chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusCircular),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.currency_rupee_rounded,
                  size: 16, color: theme.colorScheme.primary),
              Text(
                book.price.toStringAsFixed(0),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // Department chip
        _infoChip(
          theme,
          icon: Icons.school_outlined,
          label: book.department,
          isDark: isDark,
        ),
        // Category chip
        _infoChip(
          theme,
          icon: Icons.category_outlined,
          label: book.category,
          isDark: isDark,
        ),
        // Subject chip
        _infoChip(
          theme,
          icon: Icons.subject_rounded,
          label: book.subject,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _infoChip(ThemeData theme,
      {required IconData icon, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusCircular),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Stats Row ──────────────────────────────────

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          _statItem(theme, Icons.auto_stories_outlined, 'Subject',
              book.subject),
          _verticalDivider(isDark),
          _statItem(theme, Icons.school_outlined, 'Department',
              book.department),
          _verticalDivider(isDark),
          _statItem(
            theme,
            book.available
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            'Status',
            book.available 
                ? 'Available' 
                : (book.status == 'rented' ? 'Rented' : 'Sold'),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  // ─────────────────────────── Description ────────────────────────────────

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Seller Info ─────────────────────────────────

  Widget _buildSellerSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              book.sellerName.isNotEmpty
                  ? book.sellerName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name & label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.sellerName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Seller',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Message button
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Messaging coming soon!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Message'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Action Buttons ─────────────────────────────

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.editBook,
                      arguments: book);
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(theme),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  minimumSize: const Size(0, 46),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────── Bottom Bar ─────────────────────────────────

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${AppConstants.defaultCurrencySymbol}${book.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Buy / Exchange button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: book.available
                  ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) => BookingDialog(book: book),
                      );
                    }
                  : null,
              icon: Icon(
                book.available
                    ? Icons.swap_horiz_rounded
                    : Icons.block_rounded,
                size: 20,
              ),
              label: Text(book.available ? 'Buy / Exchange' : 'Not Available'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
                disabledBackgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Delete Dialog ──────────────────────────────

  void _showDeleteDialog(ThemeData theme) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this book?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          book.author,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteBook(book.id);

                // Remove from favorites if present
                if (FavoritesManager.instance.isFavorite(book)) {
                  FavoritesManager.instance.toggleFavorite(book);
                }

                if (!mounted) return;
                Navigator.pop(dialogContext); // close dialog
                Navigator.pop(context); // go back to previous screen

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${book.title}" has been deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete book: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  // ─────────────────────────── Availability Badge ─────────────────────────

  Widget _availabilityBadge(bool available, String status) {
    String text = 'Available';
    if (!available) {
      text = status == 'rented' ? 'Rented' : 'Sold Out';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? AppColors.success.withValues(alpha: 0.9)
            : AppColors.error.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppConstants.radiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
