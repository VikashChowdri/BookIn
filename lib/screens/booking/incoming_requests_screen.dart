import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';

class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view requests.'))
          : StreamBuilder<List<Booking>>(
              stream: DatabaseService.instance.getIncomingRequestsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(
                    child: Text('No pending requests.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _RequestCard(booking: request);
                  },
                );
              },
            ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final Booking booking;

  const _RequestCard({required this.booking});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isLoading = false;

  void _handleRequest(bool accept) async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService.instance.processBookingResponse(
        widget.booking.id,
        widget.booking.bookId,
        widget.booking.buyerId,
        widget.booking.bookTitle,
        accept,
      );

      // Find if there's any related unread notification for the seller and mark it read
      // We do this silently in the background
      final sellerId = AuthService.instance.currentUser?.uid;
      if (sellerId != null) {
        FirebaseFirestore.instance
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: sellerId)
            .where('relatedId', isEqualTo: widget.booking.id)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({
              'isRead': true,
              'type': accept ? 'booking_request_accepted' : 'booking_request_rejected',
            });
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Request Accepted! Book Sold.' : 'Request Rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 80,
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.getBookCover(widget.booking.bookImageUrl, widget.booking.bookId),
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
                        widget.booking.bookTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buyer ID: ${widget.booking.buyerId.substring(0, 5)}...',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dates: ${widget.booking.startDate.day}/${widget.booking.startDate.month} - ${widget.booking.endDate.day}/${widget.booking.endDate.month}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offer: ${AppConstants.defaultCurrencySymbol}${widget.booking.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => _handleRequest(false),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleRequest(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Accept Sale'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
