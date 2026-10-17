import 'package:flutter/material.dart';
import '../core/animations/app_animations.dart';
import '../models/book.dart';
import '../models/user_model.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/verification_screen.dart';
import '../screens/common/placeholder_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/favorites/wishlist_screen.dart';
import '../screens/home/add_edit_book_screen.dart';
import '../screens/home/book_details_screen.dart';
import '../screens/home/book_listing_screen.dart';
import '../screens/main_screen.dart';
import '../screens/home/my_listings_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/search/search_results_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/booking/my_rentals_screen.dart';
import '../screens/booking/my_purchases_screen.dart';
import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/booking/incoming_requests_screen.dart';
import '../models/booking.dart';
import '../screens/chat/chat_detail_screen.dart';

class AppRoutes {
  // Common / Splash
  static const String splash = '/';

  // Member 1 - Auth & User Management
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String profile = '/profile';
  static const String publicProfile = '/public-profile';
  static const String editProfile = '/edit-profile';

  // Member 2 - Book Management
  static const String home = '/home';
  static const String bookListing = '/book-listing';
  static const String bookDetails = '/book-details';
  static const String addBook = '/add-book';
  static const String editBook = '/edit-book';
  static const String myListings = '/my-listings';
  static const String myRentals = '/my-rentals';
  static const String myPurchases = '/my-purchases';
  static const String purchaseRequests = '/purchase-requests';
  static const String rentalRequests = '/rental-requests';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String notifications = '/notifications';

  // Member 3 - Search & Discovery
  static const String search = '/search';
  static const String searchResults = '/search-results';
  static const String favorites = '/favorites';
  static const String wishlist = '/wishlist';
  static const String chatDetail = '/chat-detail';

  static Map<String, WidgetBuilder> get routes => {
        // Common
        splash: (context) => const SplashScreen(),

        // Member 1: Auth & User Management — Real Screens
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        profile: (context) => const ProfileScreen(),
        editProfile: (context) => const EditProfileScreen(),

        // Member 2: Book Management
        home: (context) => const MainScreen(),
        addBook: (context) => const AddEditBookScreen(),
        myListings: (context) => const MyListingsScreen(),
        myRentals: (context) => const MyRentalsScreen(),
        myPurchases: (context) => const MyPurchasesScreen(),
        purchaseRequests: (context) => const IncomingRequestsScreen(title: 'Buyer Requests', type: 'purchase'),
        rentalRequests: (context) => const IncomingRequestsScreen(title: 'Rental Requests', type: 'rental'),
        notifications: (context) => const NotificationsScreen(),

        // Member 3: Search & Discovery — Real Screens
        search: (context) => const SearchScreen(),
        favorites: (context) => const FavoritesScreen(),
        wishlist: (context) => const WishlistScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Edit Book — requires Book argument
    if (settings.name == editBook) {
      final book = settings.arguments as Book?;
      return AppPageRoute(
        child: AddEditBookScreen(book: book),
        settings: settings,
        direction: AxisDirection.up,
      );
    }

    // Booking Confirmation — requires Booking argument
    if (settings.name == bookingConfirmation) {
      final booking = settings.arguments as Booking?;
      if (booking != null) {
        return AppPageRoute(
          child: BookingConfirmationScreen(booking: booking),
          settings: settings,
          direction: AxisDirection.up,
        );
      }
    }

    // Book Listing — optional category argument
    if (settings.name == bookListing) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      return AppPageRoute(
        child: BookListingScreen(
          initialCategory: args['category'] as String?,
        ),
        settings: settings,
      );
    }

    // Search Results — requires query arguments
    if (settings.name == searchResults) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      return AppPageRoute(
        child: SearchResultsScreen(
          query: args['query'] as String? ?? '',
          category: args['category'] as String?,
          department: args['department'] as String?,
          sortBy: args['sortBy'] as String? ?? 'Newest',
        ),
        settings: settings,
      );
    }

    // Verification — requires email argument
    if (settings.name == verification) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      return AppPageRoute(
        child: VerificationScreen(
          email: args['email'] as String? ?? '',
        ),
        settings: settings,
      );
    }

    // Book Details — accepts either a raw Book or a Map {'book': Book, 'heroTag': String?}
    if (settings.name == bookDetails) {
      Book? book;
      String? heroTag;
      if (settings.arguments is Book) {
        book = settings.arguments as Book;
      } else if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        book = args['book'] as Book?;
        heroTag = args['heroTag'] as String?;
      }
      if (book != null) {
        return AppPageRoute(
          child: BookDetailsScreen(book: book, heroTag: heroTag),
          settings: settings,
        );
      }
      return AppPageRoute(
        child: const PlaceholderScreen(
          title: 'Book Details',
          subtitle: 'No book data provided.',
          icon: Icons.menu_book_rounded,
        ),
        settings: settings,
      );
    }

    // Public Profile — requires UserModel argument
    if (settings.name == publicProfile) {
      final userModel = settings.arguments as UserModel?;
      if (userModel != null) {
        return AppPageRoute(
          child: PublicProfileScreen(user: userModel),
          settings: settings,
        );
      }
    }

    // Chat Detail — requires roomId and UserModel
    if (settings.name == chatDetail) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args != null && args['roomId'] != null && args['otherUser'] != null) {
        return AppPageRoute(
          child: ChatDetailScreen(
            roomId: args['roomId'] as String,
            otherUser: args['otherUser'] as UserModel,
            contextBook: args['contextBook'] as Book?,
          ),
          settings: settings,
        );
      }
    }

    // Fall back to static routes map
    final builder = routes[settings.name];
    if (builder != null) {
      final isModal = settings.name == addBook;
      return AppPageRoute(
        child: Builder(builder: builder),
        settings: settings,
        direction: isModal ? AxisDirection.up : AxisDirection.left,
      );
    }

    // 404
    return AppPageRoute(
      child: Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
      settings: settings,
    );
  }
}
