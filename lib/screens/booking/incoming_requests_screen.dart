import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import 'qr_scanner_screen.dart';

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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type == 'rental' ? Icons.handshake_outlined : Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No incoming ${title.toLowerCase()} found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

  String get _normalizedStatus =>
      widget.booking.status.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();

  String get _normalizedType =>
      widget.booking.type.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();

  bool get _isRental => _normalizedType == 'rental';

  bool get _isAcceptedOrActive =>
      _normalizedStatus == 'accepted' || _normalizedStatus == 'active';

  bool get _isTerminal =>
      _normalizedStatus == 'completed' ||
      _normalizedStatus == 'rejected' ||
      _normalizedStatus == 'cancelled';

  int get _rentalDays {
    final diff = widget.booking.endDate.difference(widget.booking.startDate).inDays;
    return diff > 0 ? diff : 1;
  }

  Future<void> _showConfirmationDialog(bool accept) async {
    final actionName = accept ? 'Accept' : 'Reject';
    final requestType = _isRental ? 'Rental' : 'Purchase';
    final title = '$actionName $requestType Request?';

    final message = accept
        ? (_isRental
            ? 'Are you sure you want to accept this rental request? The book will be marked as rented.'
            : 'Are you sure you want to accept this purchase request? The book will be marked as sold.')
        : 'Are you sure you want to reject this request? The book will remain available.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
        }).catchError((_) {});
      }

      if (mounted) {
        final successMsg = accept
            ? (_isRental ? 'Rental Request Accepted! Book Rented.' : 'Purchase Request Accepted! Book Sold.')
            : 'Request Rejected.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
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

    // Status chip colors and text
    final Color statusColor;
    final String statusText;
    if (_isAcceptedOrActive) {
      statusColor = Colors.green;
      statusText = _normalizedStatus == 'accepted' ? 'ACCEPTED' : 'ACTIVE';
    } else if (_isTerminal) {
      statusColor = Colors.grey;
      statusText = _normalizedStatus.toUpperCase();
    } else {
      statusColor = Colors.orange;
      statusText = 'PENDING';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 95,
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.getBookCover(widget.booking.bookImageUrl, widget.booking.bookId),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.book, size: 36, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.booking.bookTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Buyer Profile Section
                      FutureBuilder<UserModel?>(
                        future: DatabaseService.instance.getUserProfile(widget.booking.buyerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final buyer = snapshot.data;
                          if (buyer == null) {
                            return Text('Buyer: Unknown', style: theme.textTheme.bodyMedium);
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
                                  radius: 11,
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
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${buyer.publicName} (@${buyer.username})',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 6),
                      // Date / Duration info
                      if (_isRental) ...[
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Rental: ${widget.booking.startDate.day}/${widget.booking.startDate.month} - ${widget.booking.endDate.day}/${widget.booking.endDate.month} ($_rentalDays ${_rentalDays == 1 ? 'day' : 'days'})',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Direct Purchase',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Offer: ${AppConstants.defaultCurrencySymbol}${widget.booking.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isAcceptedOrActive) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRScannerScreen(
                            expectedBookingId: widget.booking.id,
                            nextStatus: _normalizedStatus == 'accepted' ? 'active' : 'completed',
                            onSuccess: () {
                              // Screen will automatically rebuild when stream updates
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text(_normalizedStatus == 'accepted' ? 'Scan to Mark Active' : 'Scan to Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (_isTerminal) ...[
                  Text(
                    'Status: $statusText',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else ...[
                  // Always show Reject and Accept for any pending or incoming state!
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => _showConfirmationDialog(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _showConfirmationDialog(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isRental ? 'Accept Rental' : 'Accept Sale'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
