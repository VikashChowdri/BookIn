import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/booking.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/globals.dart';

class BookingDialog extends StatefulWidget {
  final Book book;

  const BookingDialog({super.key, required this.book});

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  late String _bookingType; // 'purchase' or 'rental'

  @override
  void initState() {
    super.initState();
    _bookingType = widget.book.rentPrice > 0 ? 'rental' : 'purchase';
  }

  void _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  double get _totalPrice {
    if (_bookingType == 'purchase') {
      return widget.book.price;
    } else {
      if (_startDate != null && _endDate != null) {
        final days = _endDate!.difference(_startDate!).inDays;
        return widget.book.rentPrice * (days > 0 ? days : 1);
      }
      return 0;
    }
  }

  void _confirmBooking() async {
    if (_bookingType == 'rental' && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final buyerId = AuthService.instance.currentUser?.uid ?? '';
      if (buyerId.isEmpty) throw Exception('User not logged in');

      final booking = Booking(
        id: '',
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        bookImageUrl: widget.book.imageUrl,
        buyerId: buyerId,
        sellerId: widget.book.sellerId,
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate ?? DateTime.now(),
        totalPrice: _totalPrice,
        status: 'pending',
        type: _bookingType,
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.createBooking(booking);

      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      // Show notification banner
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Booking Request Sent for ${widget.book.title}!'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to confirmation screen
      Navigator.pushNamed(context, AppRoutes.bookingConfirmation, arguments: booking);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Book / Rent'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (widget.book.rentPrice > 0) ...[
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'purchase', label: Text('Buy')),
                ButtonSegment(value: 'rental', label: Text('Rent')),
              ],
              selected: {_bookingType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _bookingType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_bookingType == 'rental')
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: const Text('Select Dates'),
              subtitle: Text(
                _startDate != null && _endDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'Tap to select',
              ),
              onTap: _pickDates,
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Cost:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${AppConstants.defaultCurrencySymbol}${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmBooking,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm Booking'),
        ),
      ],
    );
  }
}
