import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid; // Firebase Auth User ID
  final String email; // Email from Auth
  String name;
  String faculty; // Will store the selected faculty option
  // Removed facultyEng
  String branch; // Added Branch field
  String batch;
  String avatarUrl;
  String status; // e.g., 'طالب'
  String studentId; // Added Student ID
  double balance; // إضافة الرصيد في المحفظة
  List<Map<String, dynamic>>
  fcmTokens; // Store FCM tokens for push notifications
  String phoneNumber; // Added phone number field

  UserProfile({
    required this.uid,
    required this.email,
    this.name = '', // Default to empty string
    this.faculty = '', // Default to empty
    this.branch = '', // Default to empty
    this.batch = '',
    this.avatarUrl = '',
    this.status = 'طالب', // Default status
    this.studentId = '', // Default to empty
    this.balance = 0.0, // قيمة افتراضية للرصيد
    this.fcmTokens = const [], // Default to empty list
    this.phoneNumber = '', // Added phone number with default empty string
  });

  // Factory constructor to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle fcmTokens properly - convert from Firestore
    List<Map<String, dynamic>> tokensList = [];
    if (data['fcmTokens'] != null) {
      tokensList = List<Map<String, dynamic>>.from(data['fcmTokens'] ?? []);
    }

    return UserProfile(
      uid: doc.id, // Use document ID as UID if storing under user's UID
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      faculty: data['faculty'] ?? '',
      branch: data['branch'] ?? '', // Added Branch
      batch: data['batch'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      status: data['status'] ?? 'طالب',
      studentId: data['studentId'] ?? '', // Added Student ID
      balance:
          (data['balance'] ?? 0.0)
              .toDouble(), // تحويل القيمة إلى double إذا كانت موجودة
      fcmTokens: tokensList, // Add FCM tokens list
      phoneNumber: data['phoneNumber'] ?? '', // Added phone number field
    );
  }

  // Method to convert UserProfile instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email, // Store email for reference, though UID is primary key
      'name': name,
      'faculty': faculty,
      'branch': branch, // Added Branch
      'batch': batch,
      'avatarUrl': avatarUrl,
      'status': status,
      'studentId': studentId, // Added Student ID
      'balance': balance, // إضافة الرصيد للبيانات المخزنة
      'fcmTokens': fcmTokens, // Add FCM tokens to stored data
      'phoneNumber': phoneNumber, // Added phone number
      // uid is usually the document ID, so not stored inside the document itself
    };
  }

  // Create a copy of the UserProfile with optional new values
  UserProfile copyWith({
    String? name,
    String? faculty,
    String? branch,
    String? batch,
    String? avatarUrl,
    String? status,
    String? studentId,
    double? balance,
    List<Map<String, dynamic>>? fcmTokens,
    String? phoneNumber,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      faculty: faculty ?? this.faculty,
      branch: branch ?? this.branch,
      batch: batch ?? this.batch,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      balance: balance ?? this.balance,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
