import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/booking.dart';
import 'package:rxdart/rxdart.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('BookingService');

  // Get user's bookings from both collections
  Stream<List<Booking>> getUserBookingsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _logger.warning('No authenticated user found');
      return Stream.value([]);
    }

    // Add some test data for demonstration
    _addTestDataIfNeeded(userId);

    try {
      _logger.info('Fetching bookings for user: $userId');

      // Stream from regular bookings collection - with error handling to prevent failure
      final Stream<List<Booking>> bookingsStream = _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            _logger.info(
              'Found ${snapshot.docs.length} bookings in bookings collection',
            );
            return snapshot.docs
                .map((doc) => Booking.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            _logger.severe('Error fetching from bookings collection: $error');
            return <Booking>[];
          });

      // Stream from checkout_requests_backup collection - with error handling
      final Stream<List<Booking>> checkoutStream = _firestore
          .collection('checkout_requests_backup')
          .where('user_id', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            _logger.info(
              'Found ${snapshot.docs.length} bookings in checkout_requests_backup collection',
            );
            return snapshot.docs.map((doc) {
              // Convert checkout request to booking format
              final data = doc.data();
              _logger.info('Processing checkout request: ${doc.id}');

              // Debug the incoming data format
              _logger.info('Checkout request data keys: ${data.keys.toList()}');
              if (data.containsKey('property_price')) {
                _logger.info('Property price: ${data['property_price']}');
              }
              if (data.containsKey('status')) {
                _logger.info('Status: ${data['status']}');
              }

              try {
                return Booking(
                  id: doc.id,
                  userId: data['user_id'] ?? '',
                  userName: data['customer_name'] ?? '',
                  userEmail: data['user_email'] ?? '',
                  apartmentId: data['property_id'] ?? '',
                  apartmentName: data['property_name'] ?? '',
                  startDate: _parseTimestamp(data['created_at']),
                  endDate: _parseTimestamp(
                    data['created_at'],
                  ).add(const Duration(days: 365)),
                  totalPrice: _parseDouble(data['property_price']),
                  status: _parseStatus(data['status']),
                  notes: data['notes'] ?? 'تم الحجز من خلال صفحة الحجز',
                  createdAt: _parseTimestamp(data['created_at']),
                  updatedAt: _parseTimestamp(
                    data['updated_at'] ?? data['created_at'],
                  ),
                );
              } catch (e) {
                _logger.severe(
                  'Error processing checkout request ${doc.id}: $e',
                );
                // Return a default booking with error information
                return Booking(
                  id: doc.id,
                  userId: userId,
                  userName: 'Error processing booking',
                  userEmail: '',
                  apartmentId: '',
                  apartmentName: data['property_name'] ?? 'Unknown property',
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 1)),
                  totalPrice: 0.0,
                  status: BookingStatus.pending,
                  notes: 'Error: $e',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }
            }).toList();
          })
          .handleError((error) {
            _logger.severe(
              'Error fetching from checkout_requests_backup collection: $error',
            );
            return <Booking>[];
          });

      // To make sure we display at least checkout requests even if bookings fail
      return Rx.combineLatest2(
        bookingsStream.onErrorReturn([]),
        checkoutStream.onErrorReturn([]),
        (List<Booking> bookings, List<Booking> checkouts) {
          final List<Booking> combined = [...bookings, ...checkouts];
          // Sort by most recent first
          combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _logger.info(
            'Combined ${bookings.length} bookings and ${checkouts.length} checkouts = ${combined.length} total',
          );
          return combined;
        },
      ).handleError((error) {
        _logger.severe('Error combining booking streams: $error');
        return <Booking>[];
      });
    } catch (e) {
      _logger.severe('Unexpected error in getUserBookingsStream: $e');
      return Stream.value([]);
    }
  }

  // Get a single booking by ID (check both collections)
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      // First try regular bookings collection
      final docSnapshot =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (docSnapshot.exists) {
        return Booking.fromFirestore(docSnapshot);
      }

      // If not found, try checkout_requests_backup collection
      final checkoutSnapshot =
          await _firestore
              .collection('checkout_requests_backup')
              .doc(bookingId)
              .get();

      if (checkoutSnapshot.exists) {
        final data = checkoutSnapshot.data()!;
        return Booking(
          id: checkoutSnapshot.id,
          userId: data['user_id'] ?? '',
          userName: data['customer_name'] ?? '',
          userEmail: data['user_email'] ?? '',
          apartmentId: data['property_id'] ?? '',
          apartmentName: data['property_name'] ?? '',
          startDate: _parseTimestamp(data['created_at']),
          endDate: _parseTimestamp(
            data['created_at'],
          ).add(const Duration(days: 365)),
          totalPrice: _parseDouble(data['property_price']),
          status: _parseStatus(data['status']),
          notes: data['notes'] ?? 'تم الحجز من خلال صفحة الحجز',
          createdAt: _parseTimestamp(data['created_at']),
          updatedAt: _parseTimestamp(data['updated_at'] ?? data['created_at']),
        );
      }

      return null;
    } catch (e) {
      _logger.severe('Error getting booking details: $e');
      return null;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      String statusStr;
      switch (status) {
        case BookingStatus.pending:
          statusStr = 'pending';
          break;
        case BookingStatus.confirmed:
          statusStr = 'confirmed';
          break;
        case BookingStatus.cancelled:
          statusStr = 'cancelled';
          break;
      }

      // Check which collection the booking belongs to
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (bookingDoc.exists) {
        // Update in bookings collection
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': statusStr,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update in checkout_requests_backup collection
        await _firestore
            .collection('checkout_requests_backup')
            .doc(bookingId)
            .update({
              'status': statusStr,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      _logger.info('Booking status updated: $bookingId to $statusStr');
      return true;
    } catch (e) {
      _logger.severe('Error updating booking status: $e');
      return false;
    }
  }

  // Create a new booking (after successful checkout)
  Future<String?> createBooking({
    required String apartmentId,
    required String apartmentName,
    required double totalPrice,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        _logger.warning('Cannot create booking: No authenticated user');
        return null;
      }

      // Get user profile for name and email
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // Format data for checkout_requests_backup collection
      final checkoutRequest = {
        'user_id': user.uid,
        'customer_name': userData?['name'] ?? user.displayName ?? '',
        'user_email': userData?['email'] ?? user.email ?? '',
        'property_id': apartmentId,
        'property_name': apartmentName,
        'property_price': totalPrice,
        'status': 'pending',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save to checkout_requests_backup collection
      final docRef = await _firestore
          .collection('checkout_requests_backup')
          .add(checkoutRequest);
      _logger.info(
        'New booking created in checkout_requests_backup with ID: ${docRef.id}',
      );

      return docRef.id;
    } catch (e) {
      _logger.severe('Error creating booking: $e');
      return null;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    return updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  // Helper method to parse timestamp from various formats
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        _logger.warning('Invalid date format: $timestamp');
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Helper method to parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  // Helper method to parse status string to BookingStatus enum
  BookingStatus _parseStatus(dynamic status) {
    if (status == null) return BookingStatus.pending;

    if (status is String) {
      final lowerStatus = status.toLowerCase().trim();
      _logger.info('Parsing status: "$status" -> "$lowerStatus"');

      switch (lowerStatus) {
        // English statuses
        case 'confirmed':
          return BookingStatus.confirmed;
        case 'cancelled':
        case 'canceled': // Allow American spelling
          return BookingStatus.cancelled;
        case 'pending':
          return BookingStatus.pending;

        // Arabic statuses
        case 'مؤكد':
          return BookingStatus.confirmed;
        case 'ملغى':
        case 'ملغي':
          return BookingStatus.cancelled;
        case 'قيد الانتظار':
        case 'جاري المعالجة': // Arabic status from checkout
          return BookingStatus.pending;

        default:
          _logger.warning('Unknown status: "$status", defaulting to pending');
          return BookingStatus.pending;
      }
    }

    return BookingStatus.pending;
  }

  // Add test data for demonstration (temporary)
  Future<void> _addTestDataIfNeeded(String userId) async {
    try {
      // Check if user already has bookings
      final existingBookings =
          await _firestore
              .collection('checkout_requests_backup')
              .where('user_id', isEqualTo: userId)
              .limit(1)
              .get();

      if (existingBookings.docs.isNotEmpty) {
        _logger.info('User already has bookings, skipping test data creation');
        return;
      }

      _logger.info('Creating test data for user: $userId');

      // Create test bookings with different statuses
      final testBookings = [
        {
          'user_id': userId,
          'customer_name': 'أحمد محمد',
          'user_email': 'ahmed@example.com',
          'property_id': 'test_1',
          'property_name': 'فيلا دوبلكس',
          'property_price': 4500.0,
          'status': 'pending',
          'notes': 'حجز تجريبي - قيد الانتظار',
          'created_at':
              DateTime.now()
                  .subtract(const Duration(days: 2))
                  .toIso8601String(),
          'updated_at':
              DateTime.now()
                  .subtract(const Duration(days: 2))
                  .toIso8601String(),
        },
        {
          'user_id': userId,
          'customer_name': 'أحمد محمد',
          'user_email': 'ahmed@example.com',
          'property_id': 'test_2',
          'property_name': 'شقة مفروشة',
          'property_price': 3200.0,
          'status': 'confirmed',
          'notes': 'حجز تجريبي - مؤكد',
          'created_at':
              DateTime.now()
                  .subtract(const Duration(days: 5))
                  .toIso8601String(),
          'updated_at':
              DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
        },
        {
          'user_id': userId,
          'customer_name': 'أحمد محمد',
          'user_email': 'ahmed@example.com',
          'property_id': 'test_3',
          'property_name': 'استوديو مودرن',
          'property_price': 2800.0,
          'status': 'cancelled',
          'notes': 'حجز تجريبي - ملغى',
          'created_at':
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String(),
          'updated_at':
              DateTime.now()
                  .subtract(const Duration(days: 3))
                  .toIso8601String(),
        },
      ];

      // Add test bookings to Firestore
      for (final booking in testBookings) {
        await _firestore.collection('checkout_requests_backup').add(booking);
      }

      _logger.info('Test data created successfully');
    } catch (e) {
      _logger.warning('Error creating test data: $e');
    }
  }
}
