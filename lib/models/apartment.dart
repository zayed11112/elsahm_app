import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class Apartment {
  final String id;
  final String name;
  final String location;
  final double price;
  final double commission;
  final double deposit;
  final int rooms;
  final List<String> images;
  final List<String> videos;
  final List<String> driveImages;
  final bool isAvailable;
  final String description;
  final List<String> features;
  final String type;
  final String floor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls;
  int currentImageIndex = 0;
  final int bedrooms;
  final int bathrooms;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String category;
  final List<Map<String, dynamic>> categories; // قائمة الأقسام المرتبطة بالعقار
  final List<Map<String, dynamic>> places; // قائمة الأماكن المتاحة المرتبطة بالعقار

  Apartment({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    this.commission = 0,
    this.deposit = 0,
    required this.rooms,
    this.images = const [],
    this.videos = const [],
    this.driveImages = const [],
    this.isAvailable = true,
    this.description = '',
    this.features = const [],
    this.type = '',
    this.floor = '',
    required this.createdAt,
    required this.updatedAt,
    List<String>? imageUrls,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.category = '',
    this.categories = const [],
    this.places = const [],
  }) : imageUrls = imageUrls ?? images;

  // Create Apartment from Supabase data
  factory Apartment.fromSupabase(Map<String, dynamic> data) {
    List<String> extractStringList(dynamic value) {
      if (value == null) return [];
      
      if (value is List) {
        return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      }
      
      if (value is String) {
        try {
          // محاولة تحويل النص إذا كان بتنسيق JSON
          if (value.startsWith('[') && value.endsWith(']')) {
            final List<dynamic> parsed = jsonDecode(value);
            return parsed.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
          }
        } catch (_) {}
        
        // إذا لم يكن بتنسيق JSON، نعيده كعنصر واحد إذا لم يكن فارغًا
        return value.isNotEmpty ? [value] : [];
      }
      
      return [];
    }
    
    // تحويل قيم الحقول المختلفة بأمان
    final List<String> images = extractStringList(data['images']);
    final List<String> videos = extractStringList(data['videos']);
    final List<String> driveImages = extractStringList(data['drive_images']);
    final List<String> features = extractStringList(data['features']);
    
    // استخدام صور الـ drive إذا كانت صور العقار فارغة
    final List<String> imageUrls = images.isNotEmpty ? images : driveImages;
    
    try {
      return Apartment(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        location: data['address']?.toString() ?? data['location']?.toString() ?? '',
        price: (data['price'] != null) ? double.tryParse(data['price'].toString()) ?? 0.0 : 0.0,
        commission: (data['commission'] != null) ? double.tryParse(data['commission'].toString()) ?? 0.0 : 0.0,
        deposit: (data['deposit'] != null) ? double.tryParse(data['deposit'].toString()) ?? 0.0 : 0.0,
        rooms: (data['rooms'] != null) ? int.tryParse(data['rooms'].toString()) ?? (data['bedrooms'] != null ? int.tryParse(data['bedrooms'].toString()) ?? 0 : 0) : (data['bedrooms'] != null ? int.tryParse(data['bedrooms'].toString()) ?? 0 : 0),
        images: images,
        videos: videos,
        driveImages: driveImages,
        isAvailable: data['is_available'] is bool ? data['is_available'] : (data['is_available'] == 'true' || data['is_available'] == 1),
        description: data['description']?.toString() ?? '',
        features: features,
        type: data['type']?.toString() ?? '',
        floor: data['floor']?.toString() ?? '',
        createdAt:
            data['created_at'] != null
                ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
        updatedAt:
            data['updated_at'] != null
                ? DateTime.tryParse(data['updated_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
        imageUrls: imageUrls,
        bedrooms: (data['bedrooms'] != null) ? int.tryParse(data['bedrooms'].toString()) ?? 0 : 0,
        bathrooms: (data['bathrooms'] != null) ? int.tryParse(data['bathrooms'].toString()) ?? ((data['beds'] != null) ? int.tryParse(data['beds'].toString()) ?? 0 : 0) : ((data['beds'] != null) ? int.tryParse(data['beds'].toString()) ?? 0 : 0),
        ownerId: data['owner_id']?.toString(),
        ownerName: data['owner_name']?.toString(),
        ownerPhone: data['owner_phone']?.toString(),
        category: data['category']?.toString() ?? data['type']?.toString() ?? '',
        categories: List<Map<String, dynamic>>.from(data['categories'] ?? []),
        places: List<Map<String, dynamic>>.from(data['places'] ?? []),
      );
    } catch (e) {
      print('خطأ أثناء تحويل بيانات العقار: $e');
      print('البيانات المستلمة: $data');
      
      // إعادة كائن بالحد الأدنى من المعلومات
      return Apartment(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? 'عقار بدون اسم',
        location: data['address']?.toString() ?? data['location']?.toString() ?? 'غير محدد',
        price: 0.0,
        rooms: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Create Apartment from Firestore document
  factory Apartment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Apartment(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      commission: (data['commission'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),
      rooms: data['rooms'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      driveImages: List<String>.from(data['driveImages'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      description: data['description'] ?? '',
      features: List<String>.from(data['features'] ?? []),
      type: data['type'] ?? '',
      floor: data['floor'] ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      ownerId: data['ownerId'],
      ownerName: data['ownerName'],
      ownerPhone: data['ownerPhone'],
      category: data['category'] ?? '',
      categories: List<Map<String, dynamic>>.from(data['categories'] ?? []),
      places: List<Map<String, dynamic>>.from(data['places'] ?? []),
    );
  }

  // Convert Apartment to Supabase data
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'address': location,
      'price': price,
      'commission': commission,
      'deposit': deposit,
      'bedrooms': bedrooms,
      'beds': bathrooms,
      'images': imageUrls,
      'videos': videos,
      'drive_images': driveImages,
      'is_available': isAvailable,
      'description': description,
      'features': features,
      'type': type,
      'floor': floor,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Convert Apartment to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'price': price,
      'commission': commission,
      'deposit': deposit,
      'rooms': rooms,
      'images': images,
      'videos': videos,
      'driveImages': driveImages,
      'isAvailable': isAvailable,
      'description': description,
      'features': features,
      'type': type,
      'floor': floor,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
      'imageUrls': imageUrls,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'category': category,
      'categories': categories,
      'places': places,
    };
  }

  // Create a copy of this apartment with the given fields updated
  Apartment copyWith({
    String? id,
    String? name,
    String? location,
    double? price,
    double? commission,
    double? deposit,
    int? rooms,
    List<String>? images,
    List<String>? videos,
    List<String>? driveImages,
    bool? isAvailable,
    String? description,
    List<String>? features,
    String? type,
    String? floor,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    int? bedrooms,
    int? bathrooms,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? category,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? places,
  }) {
    return Apartment(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      price: price ?? this.price,
      commission: commission ?? this.commission,
      deposit: deposit ?? this.deposit,
      rooms: rooms ?? this.rooms,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      driveImages: driveImages ?? this.driveImages,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      features: features ?? this.features,
      type: type ?? this.type,
      floor: floor ?? this.floor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      places: places ?? this.places,
    );
  }
}
