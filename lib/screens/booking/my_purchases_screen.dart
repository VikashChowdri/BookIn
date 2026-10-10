import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Purchases'),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view your purchases.'))
          : StreamBuilder<List<Booking>>(
              stream: DatabaseService.instance.getUserBookingsStream(userId, type: 'purchase'),
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
                    child: Text('You have no purchases.'),
                  );
                }

                // Group by groupId or fallback to createdAt string
                final Map<String, List<Booking>> groupedPurchases = {};
                for (var booking in bookings) {
                  final key = booking.groupId ?? booking.createdAt.toIso8601String();
                  if (!groupedPurchases.containsKey(key)) {
                    groupedPurchases[key] = [];
                  }
                  groupedPurchases[key]!.add(booking);
                }

                // Sort groups by latest first
                final sortedKeys = groupedPurchases.keys.toList()
                  ..sort((a, b) {
                    final dateA = groupedPurchases[a]!.first.createdAt;
                    final dateB = groupedPurchases[b]!.first.createdAt;
                    return dateB.compareTo(dateA);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final groupId = sortedKeys[index];
                    final groupBookings = groupedPurchases[groupId]!;
                    final purchaseNumber = sortedKeys.length - index;
                    final totalAmount = groupBookings.fold(0.0, (sum, b) => sum + b.totalPrice);
                    final date = groupBookings.first.createdAt;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text('Purchase #$purchaseNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${date.day}/${date.month}/${date.year} • ${groupBookings.length} items • ${AppConstants.defaultCurrencySymbol}${totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        children: groupBookings.map((booking) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 40,
                                height: 60,
                                child: CachedNetworkImage(
                                  imageUrl: AppConstants.getBookCover(booking.bookImageUrl, booking.bookId),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.book),
                                ),
                              ),
                            ),
                            title: Text(booking.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Status: ${booking.status.toUpperCase()}'),
                            trailing: Text(
                              '${AppConstants.defaultCurrencySymbol}${booking.totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
