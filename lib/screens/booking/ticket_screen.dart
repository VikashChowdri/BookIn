import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ticket_widget/ticket_widget.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';

class TicketScreen extends StatelessWidget {
  final Booking booking;

  const TicketScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final normStatus = booking.status.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    final bool isReady = normStatus == 'accepted' || normStatus == 'active';

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Book Pass', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: TicketWidget(
            width: 350,
            height: 500,
            isCornerRounded: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120.0,
                      height: 25.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        border: Border.all(width: 1.0, color: isReady ? Colors.green : Colors.orange),
                      ),
                      child: Center(
                        child: Text(
                          isReady ? 'READY FOR PICKUP' : 'PENDING APPROVAL',
                          style: TextStyle(color: isReady ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          booking.type.toUpperCase(),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Booking Pass',
                    style: TextStyle(color: Colors.black, fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    booking.bookTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ticketDetailRow('OWNER', booking.sellerId.substring(0, 5).toUpperCase(), 'DATE', DateFormat('MMM dd, yyyy').format(booking.startDate)),
                      const SizedBox(height: 10),
                      _ticketDetailRow('PRICE', '₹${booking.totalPrice.toStringAsFixed(0)}', 'STATUS', booking.status.toUpperCase()),
                    ],
                  ),
                ),
                const Spacer(),
                if (isReady) ...[
                  const Text(
                    'Show this to the owner to scan',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  QrImageView(
                    data: booking.id,
                    version: QrVersions.auto,
                    size: 150.0,
                    foregroundColor: Colors.black,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    booking.id.substring(0, 10).toUpperCase(),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ] else ...[
                  const Icon(Icons.access_time_filled, size: 80, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Ticket will be generated\nonce the owner accepts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticketDetailRow(String title1, String desc1, String title2, String desc2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title1,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              desc1,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            )
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title2,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              desc2,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            )
          ],
        )
      ],
    );
  }
}
