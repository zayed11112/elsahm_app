import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/property.dart';
import '../utils/constants.dart';

class PropertyService {
  static final Logger _logger = Logger('PropertyService');
  final String baseUrl = ApiConstants.baseUrl;

  // البيانات الافتراضية للعقارات المميزة
  final List<Property> _mockFeaturedProperties = [
    Property(
      id: 'fp1',
      title: 'شقة مميزة بحي الجامعة',
      description: 'شقة فاخرة مفروشة بالكامل على مسافة قريبة من جامعة سيناء',
      location: 'حي الجامعة',
      price: 1500,
      imageUrls: ['assets/images/banners/banner1.webp'],
      bedrooms: 3,
      bathrooms: 2,
      area: 120,
      isFeatured: true,
      isAvailable: true,
      ownerId: 'owner1',
      ownerName: 'السهم للتسكين',
      category: 'شقق فاخرة',
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    Property(
      id: 'fp2',
      title: 'شقة طلابية مشتركة',
      description: 'شقة مخصصة للطلاب بمرافق مشتركة وموقع ممتاز',
      location: 'شارع الجامعة',
      price: 800,
      imageUrls: ['assets/images/banners/banner1.webp'],
      bedrooms: 4,
      bathrooms: 2,
      area: 150,
      isFeatured: true,
      isAvailable: true,
      ownerId: 'owner1',
      ownerName: 'السهم للتسكين',
      category: 'سكن طلابي',
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
  ];

  // البيانات الافتراضية للعقارات الحديثة
  final List<Property> _mockRecentProperties = [
    Property(
      id: 'rp1',
      title: 'استوديو حديث التجهيز',
      description: 'استوديو جديد بالكامل مع جميع المرافق الأساسية',
      location: 'العريش',
      price: 600,
      imageUrls: ['assets/images/banners/banner1.webp'],
      bedrooms: 1,
      bathrooms: 1,
      area: 50,
      isFeatured: false,
      isAvailable: true,
      ownerId: 'owner1',
      ownerName: 'السهم للتسكين',
      category: 'استوديوهات',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
    Property(
      id: 'rp2',
      title: 'شقة عائلية واسعة',
      description: 'شقة واسعة مناسبة للعائلات أو مجموعات الطلاب',
      location: 'شارع السلام',
      price: 1200,
      imageUrls: ['assets/images/banners/banner1.webp'],
      bedrooms: 3,
      bathrooms: 2,
      area: 140,
      isFeatured: false,
      isAvailable: true,
      ownerId: 'owner1',
      ownerName: 'السهم للتسكين',
      category: 'شقق عائلية',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    Property(
      id: 'rp3',
      title: 'غرفة طالب مفردة',
      description: 'غرفة مفردة في سكن طلابي مشترك مع جميع الخدمات',
      location: 'بجوار الجامعة',
      price: 350,
      imageUrls: ['assets/images/banners/banner1.webp'],
      bedrooms: 1,
      bathrooms: 1,
      area: 20,
      isFeatured: false,
      isAvailable: true,
      ownerId: 'owner1',
      ownerName: 'السهم للتسكين',
      category: 'غرف مفردة',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<List<Property>> getFeaturedProperties() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/properties/featured'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        // إرجاع البيانات الافتراضية في حال فشل الاتصال بالخادم
        _logger.warning(
          'استخدام البيانات الافتراضية للعقارات المميزة بسبب: ${response.statusCode}',
        );
        return _mockFeaturedProperties;
      }
    } catch (e) {
      // إرجاع البيانات الافتراضية في حال حدوث أي خطأ
      _logger.severe('استخدام البيانات الافتراضية للعقارات المميزة بسبب: $e');
      return _mockFeaturedProperties;
    }
  }

  Future<List<Property>> getRecentProperties() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/properties/recent'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        // إرجاع البيانات الافتراضية في حال فشل الاتصال بالخادم
        _logger.warning(
          'استخدام البيانات الافتراضية للعقارات الحديثة بسبب: ${response.statusCode}',
        );
        return _mockRecentProperties;
      }
    } catch (e) {
      // إرجاع البيانات الافتراضية في حال حدوث أي خطأ
      _logger.severe('استخدام البيانات الافتراضية للعقارات الحديثة بسبب: $e');
      return _mockRecentProperties;
    }
  }

  Future<List<Property>> getPropertiesByCategory(String category) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/properties/category/$category'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        // إرجاع مزيج من البيانات الافتراضية
        _logger.warning(
          'استخدام البيانات الافتراضية للتصنيف بسبب: ${response.statusCode}',
        );
        return [..._mockFeaturedProperties, ..._mockRecentProperties]
            .where(
              (p) => p.category.toLowerCase().contains(category.toLowerCase()),
            )
            .toList();
      }
    } catch (e) {
      // إرجاع مزيج من البيانات الافتراضية
      _logger.severe('استخدام البيانات الافتراضية للتصنيف بسبب: $e');
      return [..._mockFeaturedProperties, ..._mockRecentProperties]
          .where(
            (p) => p.category.toLowerCase().contains(category.toLowerCase()),
          )
          .toList();
    }
  }

  Future<List<Property>> searchProperties(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/properties/search?q=$query'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        // بحث في البيانات الافتراضية
        final allMockProperties = [
          ..._mockFeaturedProperties,
          ..._mockRecentProperties,
        ];
        return allMockProperties
            .where(
              (p) =>
                  p.title.toLowerCase().contains(query.toLowerCase()) ||
                  p.description.toLowerCase().contains(query.toLowerCase()) ||
                  p.location.toLowerCase().contains(query.toLowerCase()) ||
                  p.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    } catch (e) {
      // بحث في البيانات الافتراضية
      final allMockProperties = [
        ..._mockFeaturedProperties,
        ..._mockRecentProperties,
      ];
      return allMockProperties
          .where(
            (p) =>
                p.title.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()) ||
                p.location.toLowerCase().contains(query.toLowerCase()) ||
                p.category.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  Future<Property> getPropertyById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/properties/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Property.fromJson(data);
      } else {
        // البحث في البيانات الافتراضية
        final allMockProperties = [
          ..._mockFeaturedProperties,
          ..._mockRecentProperties,
        ];
        final property = allMockProperties.firstWhere(
          (p) => p.id == id,
          orElse: () => throw Exception('العقار غير موجود'),
        );
        return property;
      }
    } catch (e) {
      // البحث في البيانات الافتراضية
      final allMockProperties = [
        ..._mockFeaturedProperties,
        ..._mockRecentProperties,
      ];
      final property = allMockProperties.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('العقار غير موجود'),
      );
      return property;
    }
  }
}
