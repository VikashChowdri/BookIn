import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../review/review_dialog.dart';

class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view your bookings.'))
          : StreamBuilder<List<Booking>>(
              stream: DatabaseService.instance.getUserBookingsStream(userId, type: 'rental'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('You have no active rentals.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _BookingCard(booking: booking);
                  },
                );
              },
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  void _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.instance.cancelBooking(booking.id, booking.bookId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling booking: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = booking.status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: AppConstants.getBookCover(booking.bookImageUrl, booking.bookId),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.book),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.bookTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dates: ${booking.startDate.day}/${booking.startDate.month} - ${booking.endDate.day}/${booking.endDate.month}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${AppConstants.defaultCurrencySymbol}${booking.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.status == 'pending' 
                          ? Colors.orange.withValues(alpha: 0.1)
                          : (booking.status == 'accepted' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: booking.status == 'pending' 
                            ? Colors.orange
                            : (booking.status == 'accepted' ? Colors.green : Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCancelled && booking.status == 'pending')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: 'Cancel Booking',
                onPressed: () => _cancelBooking(context),
              ),
            if (booking.status == 'accepted')
              PopupMenuButton<String>(
                icon: const Icon(Icons.rate_review_outlined),
                tooltip: 'Leave Review',
                onSelected: (action) {
                  showDialog(
                    context: context,
                    builder: (_) => ReviewDialog(
                      targetId: action == 'book' ? booking.bookId : booking.sellerId,
                      targetType: action,
                      targetName: action == 'book' ? booking.bookTitle : 'Seller',
                    ),
                  );
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'book',
                    child: Text('Review Book'),
                  ),
                  const PopupMenuItem(
                    value: 'user',
                    child: Text('Review Seller'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
