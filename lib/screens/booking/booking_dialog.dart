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
    if (_startDate == null || _endDate == null) return widget.book.price;
    final days = _endDate!.difference(_startDate!).inDays;
    // Base price + (price * days) or simple rental logic: (days == 0 ? 1 : days) * widget.book.price
    final rentalDays = days == 0 ? 1 : days;
    return rentalDays * widget.book.price;
  }

  void _confirmBooking() async {
    if (_startDate == null || _endDate == null) {
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
        startDate: _startDate!,
        endDate: _endDate!,
        totalPrice: _totalPrice,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.createBooking(booking);

      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      // Show notification banner
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Booking Confirmed for ${widget.book.title}!'),
          backgroundColor: Colors.green,
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
