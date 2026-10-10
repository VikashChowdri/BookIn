class Book {
  final String id;
  final String title;
  final String author;
  final String subject;
  final String category;
  final String department;
  final String imageUrl;
  final String description;
  final String sellerName;
  final String sellerId;
  final bool available;
  final double price;
  final double rentPrice;
  final String status; // 'available', 'rented', 'sold'

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.subject,
    required this.category,
    required this.department,
    required this.imageUrl,
    required this.description,
    required this.sellerName,
    required this.sellerId,
    required this.available,
    required this.price,
    this.rentPrice = 0.0,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'subject': subject,
      'category': category,
      'department': department,
      'imageUrl': imageUrl,
      'description': description,
      'sellerName': sellerName,
      'sellerId': sellerId,
      'available': available,
      'price': price,
      'rentPrice': rentPrice,
      'status': status,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      subject: map['subject'] ?? '',
      category: map['category'] ?? '',
      department: map['department'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      available: map['available'] ?? true,
      price: (map['price'] ?? 0.0).toDouble(),
      rentPrice: (map['rentPrice'] ?? 0.0).toDouble(),
      status: map['status'] ?? (map['available'] == false ? 'sold' : 'available'),
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? subject,
    String? category,
    String? department,
    String? imageUrl,
    String? description,
    String? sellerName,
    String? sellerId,
    bool? available,
    double? price,
    double? rentPrice,
    String? status,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      department: department ?? this.department,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sellerName: sellerName ?? this.sellerName,
      sellerId: sellerId ?? this.sellerId,
      available: available ?? this.available,
      price: price ?? this.price,
      rentPrice: rentPrice ?? this.rentPrice,
      status: status ?? this.status,
    );
  }
}
