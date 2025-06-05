import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_update.dart';

class UpdateService {
  final Logger _logger = Logger('UpdateService');
  
  // استخدام getter method للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Cache المستخدم لتخزين بيانات التحديث مؤقتاً لتحسين الأداء
  AppUpdate? _cachedUpdate;
  DateTime? _lastFetchTime;
  
  // مدة صلاحية البيانات المخزنة مؤقتاً (5 دقائق)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// جلب أحدث بيانات التحديث المتاحة
  Future<AppUpdate?> getLatestUpdate() async {
    try {
      // التحقق من البيانات المخزنة مؤقتاً
      if (_cachedUpdate != null && _lastFetchTime != null) {
        final now = DateTime.now();
        if (now.difference(_lastFetchTime!) < _cacheDuration) {
          if (kDebugMode) {
            _logger.fine('استخدام بيانات التحديث المخزنة مؤقتاً');
          }
          return _cachedUpdate;
        }
      }

      // جلب بيانات التحديث من قاعدة البيانات
      final response = await _supabase
          .from('app_updates')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // التحقق من وجود بيانات
      if (response == null) {
        return null;
      }

      // تحويل البيانات إلى كائن AppUpdate
      final update = AppUpdate.fromJson(response);
      
      // تخزين البيانات مؤقتاً
      _cachedUpdate = update;
      _lastFetchTime = DateTime.now();
      
      if (kDebugMode) {
        _logger.info('تم جلب بيانات تحديث جديدة: ${update.version}');
      }
      
      return update;
    } catch (e) {
      if (kDebugMode) {
        _logger.warning('خطأ في جلب بيانات التحديث: $e');
      }
      return null;
    }
  }
  
  // مسح البيانات المخزنة مؤقتاً
  void clearCache() {
    _cachedUpdate = null;
    _lastFetchTime = null;
  }
} 