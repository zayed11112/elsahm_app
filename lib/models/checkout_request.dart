class CheckoutRequest {
  final String? id;
  final String userId;
  final String propertyId;
  final String propertyName;
  final String customerName;
  final String customerPhone;
  final String universityId;
  final String college;
  final String status;
  final double commission;
  final double deposit;
  final DateTime createdAt;
  final DateTime updatedAt;

  CheckoutRequest({
    this.id,
    required this.userId,
    required this.propertyId,
    required this.propertyName,
    required this.customerName,
    required this.customerPhone,
    required this.universityId,
    required this.college,
    this.status = 'جاري المعالجة',
    this.commission = 0.0,
    this.deposit = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  // تحويل الكائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'property_id': propertyId,
      'property_name': propertyName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'university_id': universityId,
      'college': college,
      'status': status,
      'commission': commission,
      'deposit': deposit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // تحويل الكائن من JSON
  factory CheckoutRequest.fromJson(Map<String, dynamic> json) {
    return CheckoutRequest(
      id: json['id'],
      userId: json['user_id'],
      propertyId: json['property_id'],
      propertyName: json['property_name'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      universityId: json['university_id'],
      college: json['college'],
      status: json['status'] ?? 'جاري المعالجة',
      commission: (json['commission'] ?? 0.0).toDouble(),
      deposit: (json['deposit'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])
        : null,
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'])
        : null,
    );
  }

  // نسخ كائن مع تحديث بعض الخصائص
  CheckoutRequest copyWith({
    String? id,
    String? userId,
    String? propertyId,
    String? propertyName,
    String? customerName,
    String? customerPhone,
    String? universityId,
    String? college,
    String? status,
    double? commission,
    double? deposit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CheckoutRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      universityId: universityId ?? this.universityId,
      college: college ?? this.college,
      status: status ?? this.status,
      commission: commission ?? this.commission,
      deposit: deposit ?? this.deposit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 