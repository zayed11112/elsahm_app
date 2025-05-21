import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart';
import 'dart:io' show SocketException;

class CheckoutService {
  final Logger _logger = Logger('CheckoutService');
  
  // استخدام getter method للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;

  // إضافة طلب حجز جديد
  Future<void> addCheckoutRequest(Map<String, dynamic> checkoutData) async {
    try {
      _logger.info('إضافة طلب تسجيل خروج جديد للعقار: ${checkoutData['property_name']}');
      _logger.info('بيانات الطلب: ${checkoutData.toString()}');
      
      // التأكد من الاتصال بـ Supabase
      if (_supabase == null) {
        _logger.severe('خطأ: عميل Supabase غير موجود');
        throw Exception('Supabase client is not initialized');
      }
      
      // طباعة معلومات الاتصال للتشخيص
      _logger.info('حالة الاتصال بـ Supabase: ${_supabase.auth.currentSession != null ? 'متصل' : 'غير متصل'}');
      
      // التأكد من تنسيق البيانات بشكل صحيح ليتوافق مع هيكل الجدول في Supabase
      final sanitizedData = {
        ...checkoutData,
        // التأكد من أن البيانات من النوع الصحيح
        'commission': checkoutData['commission'] is num ? checkoutData['commission'] : double.parse('${checkoutData['commission']}'),
        'deposit': checkoutData['deposit'] is num ? checkoutData['deposit'] : double.parse('${checkoutData['deposit']}'),
        'property_price': checkoutData['property_price'] is num ? checkoutData['property_price'] : double.parse('${checkoutData['property_price']}'),
      };
      
      // تجاوز مشكلة RLS في Supabase باستخدام مفتاح الـ service_role إذا كان متاحًا
      // ملاحظة: نحتاج إلى التأكد من وجود صلاحيات كافية في إعدادات Supabase
      try {
        final response = await _supabase
            .from('checkout_requests')
            .insert(sanitizedData)
            .select();
        
        _logger.info('تم إضافة طلب تسجيل الخروج بنجاح، استجابة: $response');
      } catch (innerError) {
        _logger.warning('فشل إضافة البيانات باستخدام الطريقة الأولى: $innerError');
        
        // محاولة ثانية باستخدام upsert بدلاً من insert
        final response = await _supabase
            .from('checkout_requests')
            .upsert(sanitizedData)
            .select();
        
        _logger.info('تم إضافة طلب تسجيل الخروج بنجاح باستخدام upsert، استجابة: $response');
      }
    } catch (e, stackTrace) {
      _logger.severe('خطأ في إضافة طلب تسجيل الخروج: $e');
      _logger.severe('تفاصيل الخطأ: $stackTrace');
      
      // طباعة المزيد من التفاصيل للمساعدة في تشخيص المشكلة
      if (e is PostgrestException) {
        _logger.severe('خطأ PostgrestException: ${e.code} - ${e.message}');
        _logger.severe('تفاصيل إضافية: ${e.details}');
      } else if (e is SocketException) {
        _logger.severe('خطأ اتصال الشبكة: ${e.message}');
      }
      
      rethrow;
    }
  }

  // الحصول على طلبات تسجيل الخروج للمستخدم
  Future<List<Map<String, dynamic>>> getUserCheckoutRequests(String userId) async {
    try {
      _logger.info('جلب طلبات تسجيل الخروج للمستخدم: $userId');
      
      final response = await _supabase
          .from('checkout_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('خطأ في جلب طلبات تسجيل الخروج للمستخدم: $e');
      return [];
    }
  }

  // الحصول على طلبات تسجيل الخروج للعقار
  Future<List<Map<String, dynamic>>> getPropertyCheckoutRequests(String propertyId) async {
    try {
      _logger.info('جلب طلبات تسجيل الخروج للعقار: $propertyId');
      
      final response = await _supabase
          .from('checkout_requests')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('خطأ في جلب طلبات تسجيل الخروج للعقار: $e');
      return [];
    }
  }

  // تحديث حالة طلب تسجيل الخروج
  Future<void> updateCheckoutRequestStatus(String requestId, String status) async {
    try {
      _logger.info('تحديث حالة طلب تسجيل الخروج $requestId إلى $status');
      
      await _supabase
          .from('checkout_requests')
          .update({'status': status})
          .eq('id', requestId);
      
      _logger.info('تم تحديث حالة طلب تسجيل الخروج بنجاح');
    } catch (e) {
      _logger.severe('خطأ في تحديث حالة طلب تسجيل الخروج: $e');
      rethrow;
    }
  }

  // تحديث بيانات العمولة والعربون
  Future<void> updateCheckoutFinancials(String requestId, {double? commission, double? deposit}) async {
    try {
      _logger.info('تحديث البيانات المالية لطلب تسجيل الخروج: $requestId');
      
      final Map<String, dynamic> updateData = {};
      if (commission != null) {
        updateData['commission'] = commission;
      }
      if (deposit != null) {
        updateData['deposit'] = deposit;
      }
      
      if (updateData.isNotEmpty) {
        await _supabase
            .from('checkout_requests')
            .update(updateData)
            .eq('id', requestId);
        
        _logger.info('تم تحديث البيانات المالية بنجاح');
      }
    } catch (e) {
      _logger.severe('خطأ في تحديث البيانات المالية: $e');
      rethrow;
    }
  }

  // حذف طلب تسجيل خروج
  Future<void> deleteCheckoutRequest(String requestId) async {
    try {
      _logger.info('حذف طلب تسجيل الخروج: $requestId');
      
      await _supabase
          .from('checkout_requests')
          .delete()
          .eq('id', requestId);
      
      _logger.info('تم حذف طلب تسجيل الخروج بنجاح');
    } catch (e) {
      _logger.severe('خطأ في حذف طلب تسجيل الخروج: $e');
      rethrow;
    }
  }
  
  // الحصول على معلومات العقار من جدول properties
  Future<Map<String, dynamic>?> getPropertyDetails(String propertyId) async {
    try {
      _logger.info('جلب معلومات العقار: $propertyId');
      
      // تحديث الاستعلام ليشمل جميع البيانات بشكل صريح بدون العلاقة مع الفئة التي تسبب الخطأ
      final response = await _supabase
          .from('properties')
          .select('*, id, name, description, type, price, commission, deposit')
          .eq('id', propertyId)
          .maybeSingle();
      
      if (response != null) {
        _logger.info('تم استرجاع بيانات العقار بنجاح: ${response['id']}');
        _logger.info('مفاتيح العقار: ${response.keys.toList()}');
        
        // عرض البيانات المطلوبة (العمولة والعربون) للتشخيص
        _logger.info('قيمة العمولة: ${response['commission']}');
        _logger.info('قيمة العربون: ${response['deposit']}');
      } else {
        _logger.warning('لم يتم العثور على بيانات للعقار بالمعرف: $propertyId');
      }
      
      return response;
    } catch (e) {
      _logger.severe('خطأ في جلب معلومات العقار: $e');
      return null;
    }
  }
} 