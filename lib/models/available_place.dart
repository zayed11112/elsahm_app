class AvailablePlace {
  final int id;
  final String name;
  final String iconUrl;
  final int orderIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AvailablePlace({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.orderIndex,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // إنشاء كائن AvailablePlace من بيانات Supabase
  factory AvailablePlace.fromSupabase(Map<String, dynamic> data) {
    return AvailablePlace(
      id: data['id'] ?? 0,
      name: data['name'] ?? '',
      iconUrl: data['icon_url'] ?? '',
      orderIndex: data['order_index'] ?? 0,
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at']) 
          : DateTime.now(),
    );
  }

  // تحويل كائن AvailablePlace إلى بيانات لـ Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'icon_url': iconUrl,
      'order_index': orderIndex,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // إنشاء نسخة معدلة من الكائن
  AvailablePlace copyWith({
    int? id,
    String? name,
    String? iconUrl,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailablePlace(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 