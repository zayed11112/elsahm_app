class PaymentMethod {
  final String id;
  final String name;
  final String paymentIdentifier;
  final String? imageUrl;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.paymentIdentifier,
    this.imageUrl,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      paymentIdentifier: json['payment_identifier'] ?? '',
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'payment_identifier': paymentIdentifier,
      'image_url': imageUrl,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
