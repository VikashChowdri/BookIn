import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/book.dart';

/// A polished, reusable book card with two display modes: list tile and grid.
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool isGridMode;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGridMode ? _buildGridCard(context) : _buildListCard(context);
  }

  // ────────────────────────── List Card ──────────────────────────────────

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          onTap: onTap,
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
                        '${book.author} · ${book.subject}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusCircular),
                            ),
                            child: Text(
                              book.department,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusCircular),
                            ),
                            child: Text(
                              book.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
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
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? AppColors.error
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: onFavoriteTap,
                  visualDensity: VisualDensity.compact,
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────── Grid Card ──────────────────────────────────

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with favorite button overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.radiusMedium),
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
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
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 40,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Availability badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _availabilityChip(book.available),
                  ),
                  // Favorite button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onFavoriteTap,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.error : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info section
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
                          Text(
                            book.department,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────── Availability Chip ─────────────────────────

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
