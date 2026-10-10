import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/book.dart';
import '../../models/booking.dart';
import '../../models/notification_item.dart';
import '../../models/user_model.dart';
import '../../models/review.dart';
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
  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);
  CollectionReference get _reviewsRef =>
      _firestore.collection(AppConstants.reviewsCollection);

  // ---------------------------------------------------------------------------
  // User Profile CRUD Operations
  // ---------------------------------------------------------------------------

  Future<bool> isUsernameAvailable(String username) async {
    final snapshot = await _usersRef.where('username', isEqualTo: username).get();
    return snapshot.docs.isEmpty;
  }

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _usersRef.doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Stream<UserModel?> getUserProfileStream(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<UserModel?> getUserProfileByUsername(String username) async {
    try {
      final snapshot = await _usersRef.where('username', isEqualTo: username).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile by username: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _usersRef.get();
      final allUsers = snapshot.docs.map((doc) =>
        UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();

      final lowercaseQuery = query.toLowerCase();
      return allUsers.where((user) =>
        user.username.toLowerCase().contains(lowercaseQuery) ||
        user.publicName.toLowerCase().contains(lowercaseQuery)
      ).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete user's books
      final booksSnapshot = await _booksRef.where('sellerId', isEqualTo: userId).get();
      for (var doc in booksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's bookings (as buyer or seller)
      final buyerBookingsSnapshot = await _bookingsRef.where('buyerId', isEqualTo: userId).get();
      for (var doc in buyerBookingsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      final sellerBookingsSnapshot = await _bookingsRef.where('sellerId', isEqualTo: userId).get();
      for (var doc in sellerBookingsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's notifications
      final notificationsSnapshot = await _notificationsRef.where('userId', isEqualTo: userId).get();
      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's profile document
      batch.delete(_usersRef.doc(userId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

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

  Future<int> getUserBooksCount(String userId) async {
    try {
      final snapshot = await _booksRef.where('sellerId', isEqualTo: userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
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
        type: booking.type,
        createdAt: booking.createdAt,
      );
      await docRef.set(newBooking.toMap());
      
      // Optionally mark book as unavailable while pending
      await _booksRef.doc(booking.bookId).update({'available': false});

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

  Stream<List<Booking>> getUserBookingsStream(String userId, {String? type}) {
    var query = _bookingsRef.where('buyerId', isEqualTo: userId);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Booking>> getIncomingRequestsStream(String sellerId) {
    return _bookingsRef
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: 'pending')
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
      await _booksRef.doc(bookId).update({'available': true, 'status': 'available'});
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<int> getUserExchangesCount(String userId) async {
    try {
      // Get bookings where user is buyer
      final buyerSnapshot = await _bookingsRef
          .where('buyerId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();
          
      // Get bookings where user is seller
      final sellerSnapshot = await _bookingsRef
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();
          
      return (buyerSnapshot.count ?? 0) + (sellerSnapshot.count ?? 0);
    } catch (e) {
      return 0;
    }
  }

  Future<bool> hasSuccessfulTransaction(String buyerId, String sellerId) async {
    try {
      final snapshot = await _bookingsRef
          .where('buyerId', isEqualTo: buyerId)
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
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

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _notificationsRef.where('userId', isEqualTo: userId).get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear notifications: $e');
    }
  }

  Future<void> respondToBookingRequest(String notificationId, String bookingId, String bookId, String buyerId, String bookTitle, bool accept) async {
    try {
      // 1. Mark the seller's notification as read or update its type
      if (notificationId.isNotEmpty) {
        await _notificationsRef.doc(notificationId).update({
          'isRead': true,
          'type': accept ? 'booking_request_accepted' : 'booking_request_rejected',
        });
      }

      // 2. Perform the actual response logic
      await processBookingResponse(bookingId, bookId, buyerId, bookTitle, accept);
    } catch (e) {
      throw Exception('Failed to respond to booking request: $e');
    }
  }

  Future<void> processBookingResponse(String bookingId, String bookId, String buyerId, String bookTitle, bool accept) async {
    try {
      // 1. Update booking status
      final newStatus = accept ? 'accepted' : 'rejected';
      await _bookingsRef.doc(bookingId).update({'status': newStatus});

      // 2. If rejected, make the book available again
      if (!accept) {
        await _booksRef.doc(bookId).update({'available': true, 'status': 'available'});
      } else {
        // If accepted, fetch booking type to update book status appropriately
        final bookingDoc = await _bookingsRef.doc(bookingId).get();
        if (bookingDoc.exists) {
          final data = bookingDoc.data() as Map<String, dynamic>?;
          final type = data?['type'] as String? ?? 'purchase';
          final newBookStatus = type == 'rental' ? 'rented' : 'sold';
          await _booksRef.doc(bookId).update({'status': newBookStatus});
        }
      }

      // 3. Send a notification to the buyer
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
      throw Exception('Failed to process booking response: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reviews CRUD Operations
  // ---------------------------------------------------------------------------

  Future<void> addReview(Review review) async {
    try {
      final docRef = _reviewsRef.doc();
      final newReview = Review(
        id: docRef.id,
        targetId: review.targetId,
        targetType: review.targetType,
        reviewerId: review.reviewerId,
        reviewerName: review.reviewerName,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
      );
      await docRef.set(newReview.toMap());
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Stream<List<Review>> getReviewsForTargetStream(String targetId, String targetType) {
    return _reviewsRef
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Review.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<double> getAverageRating(String targetId, String targetType) async {
    try {
      final snapshot = await _reviewsRef
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType)
          .get();
      if (snapshot.docs.isEmpty) return 0.0;
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['rating'] ?? 0).toDouble();
      }
      return total / snapshot.docs.length;
    } catch (e) {
      return 0.0;
    }
  }
}
