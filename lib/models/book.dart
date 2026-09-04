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
  final bool available;
  final double price;

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
    required this.available,
    required this.price,
  });
}
