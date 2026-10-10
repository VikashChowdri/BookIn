import 'package:flutter/foundation.dart';
import '../models/book.dart';

class CartManager extends ChangeNotifier {
  CartManager._();
  static final CartManager instance = CartManager._();

  final List<Book> _items = [];

  List<Book> get items => List.unmodifiable(_items);

  double get totalPrice {
    return _items.fold(0, (sum, book) => sum + book.price);
  }

  void addToCart(Book book) {
    if (!isInCart(book)) {
      _items.add(book);
      notifyListeners();
    }
  }

  void removeFromCart(Book book) {
    _items.removeWhere((item) => item.id == book.id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(Book book) {
    return _items.any((item) => item.id == book.id);
  }
}
