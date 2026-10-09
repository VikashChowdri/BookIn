import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/book.dart';
import '../../models/booking.dart';
import '../../models/notification_item.dart';
import '../../core/constants/app_constants.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _booksRef =>
      _firestore.collection(AppConstants.booksCollection);
  CollectionReference get _bookingsRef =>
      _firestore.collection(AppConstants.bookingsCollection);
  CollectionReference get _notificationsRef =>
      _firestore.collection(AppConstants.notificationsCollection);

  // ---------------------------------------------------------------------------
  // Books CRUD Operations
  // ---------------------------------------------------------------------------

  /// Add a new book to the database
  Future<String> addBook(Book book) async {
    try {
      // If the book object doesn't have an ID, Firestore will auto-generate one
      final docRef = _booksRef.doc();
      final newBook = book.copyWith(id: docRef.id);
      
      await docRef.set(newBook.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  /// Update an existing book
  Future<void> updateBook(Book book) async {
    try {
      await _booksRef.doc(book.id).update(book.toMap());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  /// Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      await _booksRef.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  /// Get a single book by ID
  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await _booksRef.doc(bookId).get();
      if (doc.exists && doc.data() != null) {
        return Book.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch book: $e');
    }
  }

  /// Get a stream of all books (optionally filtered by availability)
  Stream<List<Book>> getBooksStream({bool onlyAvailable = false}) {
    Query query = _booksRef;
    
    if (onlyAvailable) {
      query = query.where('available', isEqualTo: true);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Book.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Get a stream of books for a specific user (My Listings)
  Stream<List<Book>> getUserBooksStream(String userId) {
    return _booksRef
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Book.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Search books by title or author (basic implementation)
  Future<List<Book>> searchBooks(String query) async {
    try {
      // Note: Firestore doesn't support full-text search out of the box. 
      // This is a basic prefix match or fetching all and filtering in memory.
      // For a real app, you might want to use Algolia, Typesense, or Firebase Extensions.
      final snapshot = await _booksRef
          .where('available', isEqualTo: true)
          .get();
          
      final allBooks = snapshot.docs.map((doc) => 
        Book.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();

      final lowercaseQuery = query.toLowerCase();
      return allBooks.where((book) => 
        book.title.toLowerCase().contains(lowercaseQuery) ||
        book.author.toLowerCase().contains(lowercaseQuery)
      ).toList();
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Bookings CRUD Operations
  // ---------------------------------------------------------------------------

  Future<void> createBooking(Booking booking) async {
    try {
      final docRef = _bookingsRef.doc();
      final newBooking = Booking(
        id: docRef.id,
        bookId: booking.bookId,
        bookTitle: booking.bookTitle,
        bookImageUrl: booking.bookImageUrl,
        buyerId: booking.buyerId,
        sellerId: booking.sellerId,
        startDate: booking.startDate,
        endDate: booking.endDate,
        totalPrice: booking.totalPrice,
        status: booking.status,
        createdAt: booking.createdAt,
      );
      await docRef.set(newBooking.toMap());
      
      // Optionally mark book as unavailable while pending
      await updateBookAvailability(booking.bookId, false);

      // Create a notification for the seller
      if (booking.buyerId != booking.sellerId) {
        final notifRef = _notificationsRef.doc();
        final notif = NotificationItem(
          id: notifRef.id,
          userId: booking.sellerId,
          title: 'New Booking Request!',
          body: 'Someone wants to buy/rent "${booking.bookTitle}".',
          type: 'booking_request',
          relatedId: newBooking.id,
          isRead: false,
          createdAt: DateTime.now(),
        );
        await notifRef.set(notif.toMap());
      }
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<void> updateBookAvailability(String bookId, bool available) async {
    try {
      await _booksRef.doc(bookId).update({'available': available});
    } catch (e) {
      throw Exception('Failed to update book availability: $e');
    }
  }

  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _bookingsRef.doc(bookingId).get();
      if (doc.exists && doc.data() != null) {
        return Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  Stream<List<Booking>> getUserBookingsStream(String userId) {
    return _bookingsRef
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> cancelBooking(String bookingId, String bookId) async {
    try {
      await _bookingsRef.doc(bookingId).update({'status': 'cancelled'});
      await updateBookAvailability(bookId, true);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications CRUD Operations
  // ---------------------------------------------------------------------------

  Stream<List<NotificationItem>> getUserNotificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NotificationItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> respondToBookingRequest(String notificationId, String bookingId, String bookId, String buyerId, String bookTitle, bool accept) async {
    try {
      // 1. Update booking status
      final newStatus = accept ? 'accepted' : 'rejected';
      await _bookingsRef.doc(bookingId).update({'status': newStatus});

      // 2. If rejected, make the book available again
      if (!accept) {
        await updateBookAvailability(bookId, true);
      }

      // 3. Mark the seller's notification as read or update its type
      await _notificationsRef.doc(notificationId).update({
        'isRead': true,
        'type': accept ? 'booking_request_accepted' : 'booking_request_rejected',
      });

      // 4. Send a notification to the buyer
      final notifRef = _notificationsRef.doc();
      final notif = NotificationItem(
        id: notifRef.id,
        userId: buyerId,
        title: accept ? 'Booking Accepted!' : 'Booking Rejected',
        body: accept ? 'Your request for "$bookTitle" was accepted.' : 'Your request for "$bookTitle" was rejected.',
        type: 'general',
        relatedId: bookingId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await notifRef.set(notif.toMap());
    } catch (e) {
      throw Exception('Failed to respond to booking: $e');
    }
  }
}
