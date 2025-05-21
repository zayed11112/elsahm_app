class Category {
  final String? id;
  final String name;
  final String iconName;
  final String iconUrl;
  final int orderIndex;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.id,
    required this.name,
    required this.iconName,
    this.iconUrl = '',
    this.orderIndex = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'icon_url': iconUrl,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      iconName: json['iconName'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  // تحويل من استجابة Supabase
  factory Category.fromSupabase(Map<String, dynamic> data) {
    return Category(
      id: data['id']?.toString(),
      name: data['name'] ?? '',
      iconName: _getIconNameFromUrl(data['icon_url']),
      iconUrl: data['icon_url'] ?? '',
      orderIndex: data['order_index'] ?? 0,
      isActive: data['is_active'] ?? true,
      createdAt:
          data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : null,
      updatedAt:
          data['updated_at'] != null
              ? DateTime.parse(data['updated_at'])
              : null,
    );
  }

  // تحويل رابط الأيقونة إلى اسم الأيقونة
  static String _getIconNameFromUrl(String? iconUrl) {
    if (iconUrl == null) return 'category';

    if (iconUrl.contains('meeting-room')) return 'meeting_room';
    if (iconUrl.contains('apartment')) return 'apartment';
    if (iconUrl.contains('single-bed')) return 'single_bed';
    if (iconUrl.contains('home')) return 'home';
    if (iconUrl.contains('chair')) return 'chair';
    if (iconUrl.contains('category')) return 'category';

    return 'category'; // الأيقونة الافتراضية
  }

  @override
  String toString() => 'Category(id: $id, name: $name, iconName: $iconName)';
}
