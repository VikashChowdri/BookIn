import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Notifications'),
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text('Are you sure you want to delete all notifications?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true), 
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseService.instance.clearAllNotifications(userId);
                }
              },
            ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view notifications.'))
          : StreamBuilder<List<NotificationItem>>(
              stream: DatabaseService.instance.getUserNotificationsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('No notifications.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return Dismissible(
                      key: Key(notif.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        DatabaseService.instance.deleteNotification(notif.id);
                      },
                      child: _NotificationTile(notif: notif),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final NotificationItem notif;

  const _NotificationTile({required this.notif});

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _isLoading = false;

  void _handleBookingAction(bool accept) async {
    if (widget.notif.relatedId == null) return;

    setState(() => _isLoading = true);
    try {
      final bookingId = widget.notif.relatedId!;
      final booking = await DatabaseService.instance.getBooking(bookingId);
      
      if (booking == null) {
        throw Exception('Booking not found.');
      }

      await DatabaseService.instance.respondToBookingRequest(
        widget.notif.id,
        bookingId,
        booking.bookId,
        booking.buyerId,
        booking.bookTitle,
        accept,
        type: booking.type,
      );

      if (mounted) {
        final isRental = booking.type.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase() == 'rental';
        final message = accept
            ? (isRental ? 'Rental Request Accepted!' : 'Purchase Request Accepted!')
            : 'Request Rejected';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
    final isUnread = !widget.notif.isRead;

    IconData icon;
    Color iconColor;

    final normType = widget.notif.type.replaceAll(RegExp(r'[^a-zA-Z_]'), '').toLowerCase();

    switch (normType) {
      case 'booking_request':
        icon = Icons.calendar_today;
        iconColor = Colors.orange;
        break;
      case 'booking_request_accepted':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'booking_request_rejected':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'chat_message':
        icon = Icons.chat_bubble_outline;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = theme.colorScheme.primary;
    }

    final bool canRespond = widget.notif.relatedId != null &&
        widget.notif.relatedId!.isNotEmpty &&
        !normType.contains('accepted') &&
        !normType.contains('rejected') &&
        normType != 'chat_message';

    return Card(
      elevation: isUnread ? 2 : 0,
      color: isUnread ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isUnread ? theme.colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.notif.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  _formatTime(widget.notif.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    DatabaseService.instance.deleteNotification(widget.notif.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.notif.body,
              style: theme.textTheme.bodyMedium,
            ),
            if (canRespond) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _handleBookingAction(false),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _handleBookingAction(true),
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
