import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import '../services/firestore_service.dart'; // Import FirestoreService
import '../services/notification_service.dart'; // Import NotificationService
import '../main.dart' as main; // Import main.dart for OneSignal functions

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService =
      FirestoreService(); // Instantiate FirestoreService
  final NotificationService _notificationService =
      NotificationService(); // Instantiate NotificationService
  final Logger _logger = Logger('AuthProvider');
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isNewUser = false;

  AuthProvider() : _auth = FirebaseAuth.instance {
    // Listen for authentication state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
    // Check initial state (useful if the app was closed while logged in)
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  // Get and reset isNewUser flag
  bool getAndResetIsNewUser() {
    final wasNewUser = _isNewUser;
    _isNewUser = false;
    return wasNewUser;
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      // If there was a previous user, delete their FCM token
      if (_user != null) {
        try {
          await _notificationService.deleteToken(_user!.uid);

          // إزالة ربط OneSignal للمستخدم
          await main.removeOneSignalExternalUserId();
        } catch (e) {
          _logger.severe('Error deleting tokens: $e');
        }
      }

      _user = null;
      _status = AuthStatus.unauthenticated;
      _logger.info('Auth state changed: User signed out');
    } else {
      _user = firebaseUser;
      _status = AuthStatus.authenticated;

      // Check provider info
      String authProvider = "email/password";
      if (firebaseUser.providerData.isNotEmpty) {
        final providerInfo = firebaseUser.providerData.first.providerId;
        if (providerInfo.contains('google')) {
          authProvider = 'Google';
        }
      }

      _logger.info('User authenticated with provider: $authProvider');

      // Check if this is a brand new user in Firestore
      final isCreated = await _firestoreService.createInitialUserProfile(
        _user!.uid,
        _user!.email!,
      );

      // If a new profile was created in Firestore, ensure the user is marked as new
      if (isCreated) {
        _isNewUser = true;
      }

      // Save FCM token for the user
      try {
        _logger.info(
          'Saving FCM token for user: ${_user!.uid} (Provider: $authProvider)',
        );
        await _notificationService.saveToken(_user!.uid);
        _logger.info('FCM token saved successfully');

        // ربط معرف المستخدم في OneSignal
        await main.setOneSignalExternalUserId(_user!.uid);
        _logger.info('OneSignal user ID set successfully');
      } catch (e) {
        _logger.severe('Error saving tokens: $e');
      }

      _logger.info(
        "Auth state changed: User authenticated - UID: ${_user?.uid}, Provider: $authProvider, Is new user: $_isNewUser",
      );
    }
    notifyListeners();
  }

  // Sign Up with Email and Password
  Future<bool> signUp(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      _logger.info('Starting sign up for email: $email');
      _isNewUser = true; // Mark as new user before creating account
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.info('Sign up successful - User is new: $_isNewUser');
      // State change will be handled by the listener (_onAuthStateChanged)
      return true;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Sign Up Error: ${e.message}');
      _status = AuthStatus.unauthenticated; // Reset status on error
      notifyListeners();
      //  Implement specific error handling for Firebase Auth exceptions
      // - email-already-in-use: Show "Email already registered" message
      // - weak-password: Show "Password too weak" message
      // - invalid-email: Show "Invalid email format" message
      return false;
    } catch (e) {
      _logger.severe('Sign Up Error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign In with Email and Password
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // State change will be handled by the listener (_onAuthStateChanged)
      return true;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Sign In Error: ${e.message}');
      _status = AuthStatus.unauthenticated; // Reset status on error
      notifyListeners();
      // Implement specific error handling for Firebase Auth exceptions
      // - user-not-found: Show "No account found with this email" message
      // - wrong-password: Show "Incorrect password" message
      // - invalid-email: Show "Invalid email format" message
      // - user-disabled: Show "Account has been disabled" message
      return false;
    } catch (e) {
      _logger.severe('Sign In Error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      // قم بإزالة ربط OneSignal قبل تسجيل الخروج
      await main.removeOneSignalExternalUserId();
      // تسجيل الخروج من Firebase
      await _auth.signOut();
      // State change will be handled by the listener (_onAuthStateChanged)
    } catch (e) {
      _logger.severe('Error during sign out: $e');
      // تسجيل الخروج من Firebase على أي حال
      await _auth.signOut();
    }
  }

  // Change Password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_user == null || _user!.email == null) {
      throw 'User not authenticated';
    }

    try {
      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Change password
      await _user!.updatePassword(newPassword);

      _logger.info('Password updated successfully');
    } on FirebaseAuthException catch (e) {
      _logger.severe('Change Password Error: ${e.message}');
      throw e.code;
    } catch (e) {
      _logger.severe('Change Password Error: $e');
      throw e.toString();
    }
  }

  // Reset Password (Forgot Password)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.info('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      _logger.severe('Reset Password Error: ${e.message}');
      throw e.code;
    } catch (e) {
      _logger.severe('Reset Password Error: $e');
      throw e.toString();
    }
  }

  // Sign In with Google
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      _logger.info('Starting Google sign in');
      _isNewUser = true; // Assume new user before authentication

      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If user cancels the sign-in flow
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        _logger.info('Google Sign In cancelled by user');
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      _logger.info('Google sign in successful - User is new: $_isNewUser');
      _logger.info(
        'Google user email: ${userCredential.user?.email}, UID: ${userCredential.user?.uid}',
      );
      _logger.info('FCM token will be saved in _onAuthStateChanged method');

      // State change will be handled by the listener (_onAuthStateChanged)
      return true;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Google Sign In Error: ${e.message}');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _logger.severe('Google Sign In Error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // تحديث الملف الشخصي للمستخدم
  Future<bool> updateUserProfile(String fullName) async {
    if (_user == null) {
      _logger.warning('Cannot update profile: User not authenticated');
      return false;
    }

    try {
      // تحديث الملف الشخصي في Firestore
      await _firestoreService.updateUserProfileField(_user!.uid, {
        'name': fullName,
      });

      _logger.info('User profile updated with name: $fullName');
      return true;
    } catch (e) {
      _logger.severe('Update User Profile Error: $e');
      return false;
    }
  }
}
