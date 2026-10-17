import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../widgets/app_image.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../core/animations/app_animations.dart';
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
                    return FadeSlideEntry(
                      index: index,
                      staggerDelay: const Duration(milliseconds: 40),
                      slideOffset: const Offset(0, 16),
                      child: _RequestCard(booking: request),
                    );
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

  bool get _isAccepted => _normalizedStatus == 'accepted';

  bool get _isActive => _normalizedStatus == 'active';

  bool get _isCompleted => _normalizedStatus == 'completed';

  bool get _isQrScanned => _isActive || _isCompleted;

  bool get _isTerminal =>
      _isCompleted ||
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
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
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
      if (accept) {
        // Prevent accepting if the book has already been marked as sold or rented
        try {
          final bookDoc = await FirebaseFirestore.instance
              .collection(AppConstants.booksCollection)
              .doc(widget.booking.bookId)
              .get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final bool isAvailable = bookData['available'] ?? true;
            final String currentBookStatus = bookData['status'] ?? 'available';
            if (!isAvailable && (currentBookStatus == 'sold' || currentBookStatus == 'rented')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notice: This book is already $currentBookStatus from another accepted request.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }
          }
        } catch (_) {}
      }

      await DatabaseService.instance.processBookingResponse(
        widget.booking.id,
        widget.booking.bookId,
        widget.booking.buyerId,
        widget.booking.bookTitle,
        accept,
        type: widget.booking.type,
      );

      // Silently update any related seller notifications
      final sellerId = AuthService.instance.currentUser?.uid;
      if (sellerId != null && widget.booking.id.isNotEmpty) {
        FirebaseFirestore.instance
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: sellerId)
            .where('relatedId', isEqualTo: widget.booking.id)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.set({
              'isRead': true,
              'type': accept ? 'booking_request_accepted' : 'booking_request_rejected',
            }, SetOptions(merge: true));
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
    if (_isCompleted) {
      statusColor = Colors.teal;
      statusText = _isRental ? 'COMPLETED (RETURNED)' : 'SOLD (PICKED UP)';
    } else if (_isActive) {
      statusColor = Colors.green;
      statusText = 'RENTED (ACTIVE)';
    } else if (_isAccepted) {
      statusColor = Colors.blue;
      statusText = 'ACCEPTED (AWAITING PICKUP)';
    } else if (_normalizedStatus == 'rejected') {
      statusColor = Colors.red;
      statusText = 'REJECTED';
    } else if (_normalizedStatus == 'cancelled') {
      statusColor = Colors.grey;
      statusText = 'CANCELLED';
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
                    child: AppImage(
                      imageUrl: AppConstants.getBookCover(widget.booking.bookImageUrl, widget.booking.bookId),
                      fit: BoxFit.cover,
                      placeholder: const ShimmerEffect(
                        child: ColoredBox(color: Color(0xFFE2E8F0)),
                      ),
                      errorWidget: Container(
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
                                  backgroundImage: AppImageHelper.hasCustomAvatar(buyer.profilePictureUrl)
                                      ? AppImageHelper.getImageProvider(buyer.profilePictureUrl)
                                      : null,
                                  child: !AppImageHelper.hasCustomAvatar(buyer.profilePictureUrl)
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
            if (_isQrScanned)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (_isActive ? Colors.green : Colors.teal).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_isActive ? Colors.green : Colors.teal).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 18, color: _isActive ? Colors.green : Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isActive
                            ? 'QR Code Verified: Book is rented & handed over. Accept and Reject are disabled.'
                            : (_isRental
                                ? 'Rental Completed: Book returned successfully. Accept and Reject are disabled.'
                                : 'QR Code Verified: Book is sold & picked up. Accept and Reject are disabled.'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isActive ? Colors.green.shade800 : Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isAccepted)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Request accepted! Scan the buyer\'s QR pass upon pickup to confirm handover.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Reject button - disabled when QR code is scanned or terminal
                OutlinedButton.icon(
                  onPressed: (_isQrScanned || _isTerminal || _isLoading)
                      ? null
                      : () => _showConfirmationDialog(false),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(
                    _isQrScanned
                        ? 'Reject (Disabled)'
                        : (_isAccepted ? 'Cancel Request' : 'Reject'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(
                      color: (_isQrScanned || _isTerminal) ? Colors.grey.shade400 : Colors.red,
                      width: 1.5,
                    ),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),

                // Accept button - disabled when accepted or QR code is scanned
                ElevatedButton.icon(
                  onPressed: (_isAccepted || _isQrScanned || _isTerminal || _isLoading)
                      ? null
                      : () => _handleRequest(true),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          (_isAccepted || _isQrScanned) ? Icons.check_circle : Icons.check,
                          size: 16,
                        ),
                  label: Text(
                    _isQrScanned
                        ? (_isRental ? (_isActive ? 'Rented (Active)' : 'Completed') : 'Sold')
                        : (_isAccepted
                            ? 'Accepted'
                            : (_isRental ? 'Accept Rental' : 'Accept Sale')),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: (_isAccepted || _isQrScanned)
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    disabledForegroundColor: (_isAccepted || _isQrScanned)
                        ? Colors.green.shade800
                        : Colors.grey.shade600,
                  ),
                ),

                // Scan QR code button for pickup (shown when accepted, awaiting pickup)
                if (_isAccepted)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          child: QRScannerScreen(
                            expectedBookingId: widget.booking.id,
                            nextStatus: _isRental ? 'active' : 'completed',
                            onSuccess: () {
                              // Screen will automatically rebuild when stream updates
                            },
                          ),
                          direction: AxisDirection.up,
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text(
                      'Scan QR (Pickup)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),

                // Scan QR code button for return (shown when rental is active)
                if (_isActive && _isRental)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          child: QRScannerScreen(
                            expectedBookingId: widget.booking.id,
                            nextStatus: 'completed',
                            onSuccess: () {
                              // Screen will automatically rebuild when stream updates
                            },
                          ),
                          direction: AxisDirection.up,
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text(
                      'Scan QR (Return)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
