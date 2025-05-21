class Banner {
  final int id;
  final String imageUrl;
  final int orderIndex;
  final String? title;
  final String? description;
  final String? actionUrl;
  final bool isActive;

  Banner({
    required this.id,
    required this.imageUrl,
    required this.orderIndex,
    this.title,
    this.description,
    this.actionUrl,
    required this.isActive,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      orderIndex: json['order_index'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
      actionUrl: json['action_url'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'order_index': orderIndex,
      'title': title,
      'description': description,
      'action_url': actionUrl,
      'is_active': isActive,
    };
  }
} 