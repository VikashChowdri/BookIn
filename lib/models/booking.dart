import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookImageUrl;
  final String buyerId;
  final String sellerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // e.g., 'confirmed', 'cancelled', 'completed'
  final String type; // 'rental' or 'purchase'
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookImageUrl,
    required this.buyerId,
    required this.sellerId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookImageUrl': bookImageUrl,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      bookImageUrl: map['bookImageUrl'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      type: map['type'] ?? 'rental',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
