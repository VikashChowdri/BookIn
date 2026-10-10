import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

/// A singleton service that wraps [FirebaseAuth] and exposes every
/// authentication operation the app needs.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // Streams & getters
  // ---------------------------------------------------------------------------

  /// Emits whenever the auth state changes (login / logout / token refresh).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  // ---------------------------------------------------------------------------
  // Email / Password — Sign Up
  // ---------------------------------------------------------------------------

  /// Creates a new user account and sends a verification email.
  /// Also creates a user profile document in Firestore.
  /// Throws [AuthException] with a human-readable message on failure.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String publicName,
  }) async {
    try {
      // 1. Check if username is already taken
      final isAvailable = await DatabaseService.instance.isUsernameAvailable(username);
      if (!isAvailable) {
        throw AuthException('username-taken', 'Username is already taken. Please choose another.');
      }

      // 2. Create Auth Account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 3. Set display name in Auth
      if (publicName.isNotEmpty) {
        await credential.user?.updateDisplayName(publicName);
      }

      // 4. Create User Profile in Firestore
      if (credential.user != null) {
        final userModel = UserModel(
          id: credential.user!.uid,
          username: username,
          email: email.trim(),
          publicName: publicName,
          profilePictureUrl: AppConstants.defaultUserAvatar,
          createdAt: DateTime.now(),
        );
        await DatabaseService.instance.createUserProfile(userModel);
      }

      // 5. Navigate without verification for now (Removed sendEmailVerification)

      return credential;
    } on FirebaseException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Email / Password — Sign In
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with either email or username.
  Future<UserCredential> signInWithUsernameOrEmail({
    required String identifier,
    required String password,
  }) async {
    try {
      String emailToUse = identifier.trim();
      
      // If the identifier doesn't look like an email, assume it's a username
      if (!emailToUse.contains('@')) {
        final userProfile = await DatabaseService.instance.getUserProfileByUsername(emailToUse);
        if (userProfile == null) {
          throw AuthException('user-not-found', 'No account found with this username.');
        }
        emailToUse = userProfile.email;
      }
      
      return await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );
    } on FirebaseException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Email Verification
  // ---------------------------------------------------------------------------

  /// Resends the verification email to the current user.
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseException catch (e) {
      throw _mapException(e);
    }
  }

  /// Reloads the current user from the server and returns `true` if the
  /// email is now verified.
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ---------------------------------------------------------------------------
  // Password Reset
  // ---------------------------------------------------------------------------

  /// Sends a password-reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Account Deletion
  // ---------------------------------------------------------------------------

  /// Deletes the current user's account and all associated data.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // 1. Delete data from Firestore
        await DatabaseService.instance.deleteUserData(user.uid);
        // 2. Delete Auth account
        await user.delete();
      } on FirebaseException catch (e) {
        throw _mapException(e);
      }
    } else {
      throw AuthException('no-user', 'No user is currently signed in.');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps Firebase error codes to friendly, user-facing messages.
  AuthException _mapException(FirebaseException e) {
    final String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password sign-in is not enabled. Contact support.';
        break;
      case 'weak-password':
        message = 'The password is too weak. Use at least 6 characters.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Contact support.';
        break;
      case 'user-not-found':
        message = 'No account found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-credential':
        message = 'Invalid email or password. Please check and try again.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Check your internet connection.';
        break;
      default:
        message = e.message ?? 'An unexpected error occurred.';
    }
    return AuthException(e.code, message);
  }
}

/// A lightweight exception wrapper with a user-readable [message].
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}
