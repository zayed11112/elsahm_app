import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import '../services/firestore_service.dart'; // Import FirestoreService
import '../services/notification_service.dart'; // Import NotificationService
import '../main.dart' as main; // Import main.dart for OneSignal functions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isNewUser = false;
  bool _isLoading = false;

  // Password reset attempt tracking
  int _passwordResetAttempts = 0;
  DateTime? _firstResetAttemptTime;
  final int _maxResetAttempts = 3;
  final Duration _resetAttemptsWindow = const Duration(hours: 12);

  AuthProvider() : _auth = FirebaseAuth.instance {
    // Listen for authentication state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
    // Check initial state (useful if the app was closed while logged in)
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
    _loadResetAttemptsData();
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;

  // Password reset attempt tracking getters
  int get passwordResetAttempts => _passwordResetAttempts;
  int get maxResetAttempts => _maxResetAttempts;
  DateTime? get firstResetAttemptTime => _firstResetAttemptTime;
  Duration get resetAttemptsWindow => _resetAttemptsWindow;

  // Get remaining attempts
  int get remainingResetAttempts => _maxResetAttempts - _passwordResetAttempts;

  // Check if reset attempts are allowed
  bool get canRequestPasswordReset {
    // If no attempts have been made yet
    if (_passwordResetAttempts == 0) return true;

    // If max attempts reached, check if the time window has passed
    if (_passwordResetAttempts >= _maxResetAttempts) {
      if (_firstResetAttemptTime == null) return true;

      final now = DateTime.now();
      final windowEnd = _firstResetAttemptTime!.add(_resetAttemptsWindow);

      // If the time window has passed, reset counter and allow
      if (now.isAfter(windowEnd)) {
        _resetAttemptsCounter();
        return true;
      }

      return false;
    }

    return true;
  }

  // Get time remaining until new attempts are allowed
  Duration? get timeUntilNextAttempt {
    if (_firstResetAttemptTime == null ||
        _passwordResetAttempts < _maxResetAttempts) {
      return null;
    }

    final now = DateTime.now();
    final windowEnd = _firstResetAttemptTime!.add(_resetAttemptsWindow);

    if (now.isAfter(windowEnd)) {
      return null;
    }

    return windowEnd.difference(now);
  }

  // Load reset attempts data from SharedPreferences
  Future<void> _loadResetAttemptsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _passwordResetAttempts = prefs.getInt('password_reset_attempts') ?? 0;

      final timestamp = prefs.getInt('first_reset_attempt_time');
      if (timestamp != null) {
        _firstResetAttemptTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        // Check if the time window has passed
        final now = DateTime.now();
        final windowEnd = _firstResetAttemptTime!.add(_resetAttemptsWindow);
        if (now.isAfter(windowEnd)) {
          _resetAttemptsCounter();
        }
      }
    } catch (e) {
      _logger.severe('Failed to load reset attempts data: $e');
      _resetAttemptsCounter();
    }
  }

  // Save reset attempts data to SharedPreferences
  Future<void> _saveResetAttemptsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('password_reset_attempts', _passwordResetAttempts);

      if (_firstResetAttemptTime != null) {
        await prefs.setInt(
          'first_reset_attempt_time',
          _firstResetAttemptTime!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove('first_reset_attempt_time');
      }
    } catch (e) {
      _logger.severe('Failed to save reset attempts data: $e');
    }
  }

  // Reset the attempts counter
  void _resetAttemptsCounter() {
    _passwordResetAttempts = 0;
    _firstResetAttemptTime = null;
    _saveResetAttemptsData();
  }

  // Track a password reset attempt
  void _trackResetAttempt() {
    if (_passwordResetAttempts == 0) {
      _firstResetAttemptTime = DateTime.now();
    }

    _passwordResetAttempts++;
    _saveResetAttemptsData();
  }

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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _isNewUser = false;
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
      _isLoading = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // State change will be handled by the listener (_onAuthStateChanged)
      _isLoading = false;
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
      _isLoading = false;
      return false;
    } catch (e) {
      _logger.severe('Sign In Error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      _isLoading = false;
      return false;
    }
  }

  // Sign Out
  Future<void> signOut(BuildContext? context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // قم بإزالة ربط OneSignal قبل تسجيل الخروج
      await main.removeOneSignalExternalUserId();
      // تسجيل الخروج من Firebase
      await _auth.signOut();
      // State change will be handled by the listener (_onAuthStateChanged)

      // Clear any locally stored auth data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');

      _user = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();

      // Show success message if context is provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم تسجيل الخروج بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error during sign out: $e');
      // تسجيل الخروج من Firebase على أي حال
      await _auth.signOut();
      _isLoading = false;
      notifyListeners();

      // Show error message if context is provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تسجيل الخروج: ${e.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  // Reset Password (Forgot Password) - Updated with attempt tracking
  Future<void> resetPassword(String email) async {
    // Check if reset attempts are allowed
    if (!canRequestPasswordReset) {
      final timeLeft = timeUntilNextAttempt;
      final hours = timeLeft?.inHours ?? 0;
      final minutes = (timeLeft?.inMinutes ?? 0) % 60;

      throw 'لقد تجاوزت الحد المسموح به من المحاولات، يرجى المحاولة مرة أخرى بعد $hours ساعة و $minutes دقيقة';
    }

    try {
      // Track this attempt
      _trackResetAttempt();

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
      _isLoading = true;
      notifyListeners();

      _logger.info('🔍 بدء عملية تسجيل الدخول بجوجل');
      _isNewUser = true; // Assume new user before authentication

      // إعادة تهيئة مكون GoogleSignIn مع إعدادات محددة للـ release
      try {
        // تدمير المكون الحالي وإعادة إنشائه
        await _googleSignIn.signOut();
        _logger.info('🔄 تم إعادة تهيئة مكون GoogleSignIn');
      } catch (resetError) {
        _logger.warning('⚠️ خطأ في إعادة تهيئة GoogleSignIn: $resetError');
        // نتجاهل الخطأ ونستمر
      }

      // Trigger the Google sign-in flow مع معالجة أفضل للأخطاء
      _logger.info('🔍 جاري استدعاء واجهة تسجيل الدخول من جوجل...');
      GoogleSignInAccount? googleUser;

      try {
        // محاولة تسجيل الدخول مع timeout
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            _logger.warning('⏰ انتهت مهلة تسجيل الدخول بجوجل');
            return null;
          },
        );
      } catch (signInError) {
        _logger.severe('❌ خطأ في استدعاء واجهة تسجيل الدخول: $signInError');
        _logger.severe('❌ نوع الخطأ: ${signInError.runtimeType}');

        // محاولة مرة أخرى بطريقة بديلة مع إعدادات مختلفة
        _logger.info('🔄 محاولة استخدام طريقة بديلة للتسجيل...');
        try {
          // إنشاء مكون جديد تماماً
          final alternativeGoogleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
          );
          googleUser = await alternativeGoogleSignIn.signIn().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              _logger.warning('⏰ انتهت مهلة المحاولة البديلة');
              return null;
            },
          );
        } catch (alternativeError) {
          _logger.severe('❌ فشلت المحاولة البديلة أيضاً: $alternativeError');
          googleUser = null;
        }
      }

      // If user cancels the sign-in flow
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        _logger.info('❌ تم إلغاء تسجيل الدخول بواسطة المستخدم');
        _isLoading = false;
        return false;
      }

      _logger.info('✅ تم اختيار حساب جوجل: ${googleUser.email}');

      try {
        // Obtain the auth details from the request
        _logger.info('🔍 جاري الحصول على معلومات المصادقة...');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        _logger.info('✅ تم الحصول على معلومات المصادقة:');
        _logger.info(
          '   - accessToken: ${googleAuth.accessToken != null ? "موجود" : "غير موجود"}',
        );
        _logger.info(
          '   - idToken: ${googleAuth.idToken != null ? "موجود" : "غير موجود"}',
        );

        // التأكد من وجود الرموز المطلوبة
        if (googleAuth.idToken == null) {
          _logger.severe('❌ لم يتم الحصول على idToken من جوجل!');
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          _isLoading = false;
          return false;
        }

        // Create a new credential
        _logger.info('🔍 إنشاء بيانات اعتماد لفايربيس...');
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        _logger.info('🔍 تسجيل الدخول إلى Firebase...');
        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        _user = userCredential.user;
        _isNewUser = false;
        _logger.info('✅ تسجيل الدخول بنجاح - معرف المستخدم: ${_user?.uid}');
        _logger.info('✅ البريد الإلكتروني: ${userCredential.user?.email}');

        return true;
      } catch (innerError) {
        _logger.severe('❌ خطأ أثناء عملية المصادقة: ${innerError.toString()}');

        // تفاصيل الخطأ
        if (innerError is FirebaseAuthException) {
          _logger.severe('❌ رمز الخطأ: ${innerError.code}');
          _logger.severe('❌ رسالة الخطأ: ${innerError.message}');
        }

        _status = AuthStatus.unauthenticated;
        notifyListeners();
        _isLoading = false;
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _logger.severe('❌ خطأ مصادقة Firebase: ${e.message}');
      _logger.severe('❌ رمز الخطأ: ${e.code}');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      _isLoading = false;
      return false;
    } catch (e) {
      _logger.severe('❌ خطأ عام أثناء تسجيل الدخول بجوجل: ${e.toString()}');

      // طباعة نوع الخطأ
      _logger.severe('❌ نوع الخطأ: ${e.runtimeType}');

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      _isLoading = false;
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

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting user profile: $e');
      return null;
    }
  }
}
