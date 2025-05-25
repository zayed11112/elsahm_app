import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/complaint.dart';
import '../models/user_profile.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String complaintsCollection = 'complaints';
  final uuid = Uuid();

  // Get all complaints for a user
  Stream<List<Complaint>> getUserComplaints(String userId) {
    return _firestore
        .collection(complaintsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Complaint.fromFirestore(doc)).toList();
        });
  }

  // Get a specific complaint by ID
  Stream<Complaint?> getComplaintById(String complaintId) {
    return _firestore
        .collection(complaintsCollection)
        .doc(complaintId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return Complaint.fromFirestore(doc);
          }
          return null;
        });
  }

  // Create a new complaint
  Future<String> createComplaint({
    required String userId,
    required String userName,
    required String title,
    required String description,
  }) async {
    final complaintId = uuid.v4();
    
    await _firestore.collection(complaintsCollection).doc(complaintId).set({
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'status': 'open',
      'createdAt': Timestamp.now(),
      'responses': [],
    });
    
    return complaintId;
  }

  // Add a response to a complaint
  Future<void> addResponse({
    required String complaintId,
    required String responseText,
    required String responderId,
    required String responderName,
    required bool isAdmin,
    String? imageUrl,
  }) async {
    final responseId = uuid.v4();
    final response = ComplaintResponse(
      id: responseId,
      responseText: responseText,
      responderId: responderId,
      responderName: responderName,
      isAdmin: isAdmin,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
    );

    // Get the current complaint document
    final complaintDoc = await _firestore.collection(complaintsCollection).doc(complaintId).get();
    
    if (complaintDoc.exists) {
      List<dynamic> currentResponses = complaintDoc.data()?['responses'] ?? [];
      currentResponses.add(response.toMap());
      
      // Update the document with the new response
      await _firestore.collection(complaintsCollection).doc(complaintId).update({
        'responses': currentResponses,
      });
    }
  }

  // Update complaint status
  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    await _firestore.collection(complaintsCollection).doc(complaintId).update({
      'status': newStatus,
    });
  }

  // Delete a complaint
  Future<void> deleteComplaint(String complaintId) async {
    await _firestore.collection(complaintsCollection).doc(complaintId).delete();
  }
} 