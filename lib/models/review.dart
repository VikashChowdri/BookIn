import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String targetId; // bookId or userId
  final String targetType; // 'book' or 'user'
  final String reviewerId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetId': targetId,
      'targetType': targetType,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String documentId) {
    return Review(
      id: documentId,
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'user',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Anonymous',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
