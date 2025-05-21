class BookingRequest {
  final String? id;
  final String apartmentId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String notes;
  final DateTime requestedDate;
  final String userId;
  final double apartmentPrice;
  final String status; // pending, confirmed, cancelled
  final DateTime createdAt;

  BookingRequest({
    this.id,
    required this.apartmentId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    this.notes = '',
    required this.requestedDate,
    required this.userId,
    required this.apartmentPrice,
    this.status = 'pending',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'notes': notes,
      'requestedDate': requestedDate.toIso8601String(),
      'userId': userId,
      'apartmentPrice': apartmentPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'],
      apartmentId: json['apartmentId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'] ?? '',
      notes: json['notes'] ?? '',
      requestedDate: DateTime.parse(json['requestedDate']),
      userId: json['userId'],
      apartmentPrice: json['apartmentPrice'].toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
} 