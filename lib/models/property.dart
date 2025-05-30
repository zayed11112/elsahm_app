class Property {
  final String id;
  final String title;
  final String description;
  final String location;
  final double price;
  final String? priceType;
  final List<String> imageUrls;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final bool isFeatured;
  final bool isAvailable;
  final String ownerId;
  final String ownerName;
  final String ownerPhotoUrl;
  final String category;
  final List<String> amenities;
  final DateTime createdAt;
  final DateTime updatedAt;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    this.priceType,
    required this.imageUrls,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    this.isFeatured = false,
    this.isAvailable = true,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl = '',
    required this.category,
    this.amenities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Property copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? price,
    String? priceType,
    List<String>? imageUrls,
    int? bedrooms,
    int? bathrooms,
    double? area,
    bool? isFeatured,
    bool? isAvailable,
    String? ownerId,
    String? ownerName,
    String? ownerPhotoUrl,
    String? category,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      imageUrls: imageUrls ?? this.imageUrls,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      isFeatured: isFeatured ?? this.isFeatured,
      isAvailable: isAvailable ?? this.isAvailable,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      category: category ?? this.category,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      price: (json['price'] as num).toDouble(),
      priceType: json['price_type'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      area: (json['area'] as num).toDouble(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerPhotoUrl: json['ownerPhotoUrl'] as String? ?? '',
      category: json['category'] as String,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'] as List)
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'price_type': priceType,
      'imageUrls': imageUrls,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'isFeatured': isFeatured,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'category': category,
      'amenities': amenities,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 