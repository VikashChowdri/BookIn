import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';

class IncomingRequestsScreen extends StatelessWidget {
  final String title;
  final String type;

  const IncomingRequestsScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view requests.'))
          : StreamBuilder<List<Booking>>(
              stream: DatabaseService.instance.getIncomingRequestsStream(userId, type: type),
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

  Future<void> _showConfirmationDialog(bool accept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(accept ? 'Accept Request?' : 'Reject Request?'),
          content: Text(accept
              ? 'Are you sure you want to accept this booking request? The book will be marked as sold.'
              : 'Are you sure you want to reject this request? The book will remain available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accept ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(accept ? 'Yes, Accept' : 'Yes, Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _handleRequest(accept);
    }
  }

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
                      const SizedBox(height: 8),
                      // Buyer Profile Section
                      FutureBuilder<UserModel?>(
                        future: DatabaseService.instance.getUserProfile(widget.booking.buyerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final buyer = snapshot.data;
                          if (buyer == null) {
                            return Text('Unknown Buyer', style: theme.textTheme.bodyMedium);
                          }
                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.publicProfile,
                                arguments: buyer,
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: theme.colorScheme.primary,
                                  backgroundImage: buyer.profilePictureUrl.isNotEmpty && !buyer.profilePictureUrl.contains('unsplash')
                                      ? NetworkImage(buyer.profilePictureUrl)
                                      : null,
                                  child: buyer.profilePictureUrl.isEmpty || buyer.profilePictureUrl.contains('unsplash')
                                      ? Text(
                                          buyer.publicName.isNotEmpty ? buyer.publicName[0].toUpperCase() : 'U',
                                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimary),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${buyer.publicName} (@${buyer.username})',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
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
                  onPressed: _isLoading ? null : () => _showConfirmationDialog(false),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _showConfirmationDialog(true),
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
