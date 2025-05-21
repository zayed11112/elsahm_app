import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
}

class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String apartmentId;
  final String apartmentName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.apartmentId,
    required this.apartmentName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert BookingStatus to string
  static String bookingStatusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'قيد الانتظار';
      case BookingStatus.confirmed:
        return 'مؤكد';
      case BookingStatus.cancelled:
        return 'ملغى';
      default:
        return 'غير معروف';
    }
  }

  // Convert string to BookingStatus
  static BookingStatus stringToBookingStatus(String statusStr) {
    switch (statusStr) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  // Create Booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      apartmentId: data['apartmentId'] ?? '',
      apartmentName: data['apartmentName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: stringToBookingStatus(data['status'] ?? 'pending'),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Booking to Firestore data
  Map<String, dynamic> toFirestore() {
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
      default:
        statusStr = 'pending';
    }

    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'apartmentId': apartmentId,
      'apartmentName': apartmentName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': statusStr,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Create a copy of this booking with the given fields updated
  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? apartmentId,
    String? apartmentName,
    DateTime? startDate,
    DateTime? endDate,
    double? totalPrice,
    BookingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      apartmentId: apartmentId ?? this.apartmentId,
      apartmentName: apartmentName ?? this.apartmentName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 