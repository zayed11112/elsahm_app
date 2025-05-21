import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner.dart' as app_banner;

class BannerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// جلب كل البانرات من قاعدة البيانات
  Future<List<app_banner.Banner>> getBanners() async {
    try {
      print('بدء جلب البانرات...');
      
      final response = await _supabase
          .from('banners')
          .select('*')
          .order('order_index', ascending: true);
      
      print('تم استلام الاستجابة من Supabase: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');
      
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      print('عدد البانرات الكلي: ${data.length}');
      
      final activeBanners = data
          .where((item) => item['is_active'] == true)
          .map((item) {
            print('بانر: ID=${item['id']}, URL=${item['image_url']}');
            return app_banner.Banner.fromJson(item);
          })
          .toList();
      
      print('عدد البانرات النشطة: ${activeBanners.length}');
      
      return activeBanners;
    } catch (e) {
      print('خطأ في جلب البانرات: $e');
      if (e is PostgrestException) {
        print('خطأ Postgrest: ${e.code}, ${e.message}, ${e.details}');
      }
      return [];
    }
  }
  
  /// جلب كل البانرات بما في ذلك غير النشطة (للاستخدام الإداري)
  Future<List<app_banner.Banner>> getAllBanners() async {
    try {
      final response = await _supabase
          .from('banners')
          .select('*')
          .order('order_index', ascending: true);
      
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      return data.map((item) => app_banner.Banner.fromJson(item)).toList();
    } catch (e) {
      print('خطأ في جلب كل البانرات: $e');
      return [];
    }
  }
  
  /// إضافة بانر جديد (للاستخدام الإداري فقط)
  Future<bool> addBanner({
    required String imageUrl,
    required int orderIndex,
    String? title,
    String? description,
    String? actionUrl,
  }) async {
    try {
      await _supabase.from('banners').insert({
        'image_url': imageUrl,
        'order_index': orderIndex,
        'title': title,
        'description': description,
        'action_url': actionUrl,
        'is_active': true,
      });
      
      return true;
    } catch (e) {
      print('خطأ في إضافة بانر: $e');
      return false;
    }
  }
  
  /// تحديث بانر موجود (للاستخدام الإداري فقط)
  Future<bool> updateBanner({
    required int id,
    String? imageUrl,
    int? orderIndex,
    String? title,
    String? description,
    String? actionUrl,
    bool? isActive,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (orderIndex != null) updates['order_index'] = orderIndex;
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (actionUrl != null) updates['action_url'] = actionUrl;
    if (isActive != null) updates['is_active'] = isActive;
    
    if (updates.isEmpty) return true;
    
    try {
      await _supabase
          .from('banners')
          .update(updates)
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('خطأ في تحديث البانر: $e');
      return false;
    }
  }
  
  /// حذف بانر (للاستخدام الإداري فقط)
  Future<bool> deleteBanner(int id) async {
    try {
      await _supabase
          .from('banners')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('خطأ في حذف البانر: $e');
      return false;
    }
  }
} 