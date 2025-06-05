class AppUpdate {
  final int id;
  final String version;
  final String description;
  final String downloadUrl;
  final bool isActive;
  final String? primaryColor;
  final String? secondaryColor;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUpdate({
    required this.id,
    required this.version,
    required this.description,
    required this.downloadUrl,
    required this.isActive,
    this.primaryColor,
    this.secondaryColor,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      id: json['id'] as int,
      version: json['version'] as String,
      description: json['description'] as String,
      downloadUrl: json['download_url'] as String,
      isActive: json['is_active'] as bool,
      primaryColor: json['primary_color'] as String?,
      secondaryColor: json['secondary_color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'description': description,
      'download_url': downloadUrl,
      'is_active': isActive,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 