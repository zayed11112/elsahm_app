import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method.dart';

class PaymentMethodsService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final Logger _logger = Logger('PaymentMethodsService');
  
  // الحصول على جميع طرق الدفع المتاحة
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      _logger.info('جاري تحميل طرق الدفع المتاحة...');
      
      final response = await _supabaseClient
          .from('payment_methods')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      
      _logger.info('تم استلام ${response.length} طريقة دفع من قاعدة البيانات');
      
      return (response as List)
          .map((data) => PaymentMethod.fromJson(data))
          .toList();
    } catch (e) {
      _logger.severe('خطأ في تحميل طرق الدفع: $e');
      return [];
    }
  }
  
  // إضافة طريقة دفع جديدة (للمسؤول)
  Future<bool> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      await _supabaseClient.from('payment_methods').insert(paymentMethod.toJson());
      _logger.info('تم إضافة طريقة دفع جديدة: ${paymentMethod.name}');
      return true;
    } catch (e) {
      _logger.severe('خطأ في إضافة طريقة دفع: $e');
      return false;
    }
  }
  
  // تحديث طريقة دفع موجودة (للمسؤول)
  Future<bool> updatePaymentMethod(PaymentMethod paymentMethod) async {
    try {
      await _supabaseClient
          .from('payment_methods')
          .update(paymentMethod.toJson())
          .eq('id', paymentMethod.id);
      
      _logger.info('تم تحديث طريقة الدفع: ${paymentMethod.name}');
      return true;
    } catch (e) {
      _logger.severe('خطأ في تحديث طريقة الدفع: $e');
      return false;
    }
  }
  
  // تغيير حالة طريقة الدفع (تفعيل/تعطيل) (للمسؤول)
  Future<bool> togglePaymentMethodStatus(String id, bool isActive) async {
    try {
      await _supabaseClient
          .from('payment_methods')
          .update({'is_active': isActive})
          .eq('id', id);
      
      _logger.info('تم تغيير حالة طريقة الدفع (${isActive ? 'تفعيل' : 'تعطيل'})');
      return true;
    } catch (e) {
      _logger.severe('خطأ في تغيير حالة طريقة الدفع: $e');
      return false;
    }
  }
  
  // حذف طريقة دفع (للمسؤول)
  Future<bool> deletePaymentMethod(String id) async {
    try {
      await _supabaseClient
          .from('payment_methods')
          .delete()
          .eq('id', id);
      
      _logger.info('تم حذف طريقة الدفع');
      return true;
    } catch (e) {
      _logger.severe('خطأ في حذف طريقة الدفع: $e');
      return false;
    }
  }
}
