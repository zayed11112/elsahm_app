import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String status; // 'open', 'in-progress', 'closed'
  final DateTime createdAt;
  final List<ComplaintResponse> responses;

  Complaint({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.responses = const [],
  });

  // Create from Firestore document
  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<ComplaintResponse> responses = [];
    if (data['responses'] != null) {
      responses = (data['responses'] as List)
          .map((response) => ComplaintResponse.fromMap(response))
          .toList();
    }
    
    return Complaint(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      responses: responses,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'responses': responses.map((response) => response.toMap()).toList(),
    };
  }
}

class ComplaintResponse {
  final String id;
  final String responseText;
  final String responderId;
  final String responderName;
  final bool isAdmin;
  final DateTime createdAt;
  final String? imageUrl; // Added field for image URL

  ComplaintResponse({
    required this.id,
    required this.responseText,
    required this.responderId,
    required this.responderName,
    required this.isAdmin,
    required this.createdAt,
    this.imageUrl, // Optional image URL
  });

  // Create from map
  factory ComplaintResponse.fromMap(Map<String, dynamic> data) {
    return ComplaintResponse(
      id: data['id'] ?? '',
      responseText: data['responseText'] ?? '',
      responderId: data['responderId'] ?? '',
      responderName: data['responderName'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'], // May be null
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'responseText': responseText,
      'responderId': responderId,
      'responderName': responderName,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl, // Include in the map even if null
    };
  }
} 