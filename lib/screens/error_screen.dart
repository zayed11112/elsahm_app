import 'package:flutter/material.dart';
import 'dart:io';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final bool isConnectionError;

  const ErrorScreen({
    super.key,
    required this.errorMessage,
    this.isConnectionError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // أيقونة الخطأ
              Icon(
                isConnectionError ? Icons.signal_wifi_off : Icons.error_outline,
                size: 80,
                color: isConnectionError 
                  ? Colors.orange 
                  : Colors.red,
              ),
              
              const SizedBox(height: 24),
              
              // عنوان الخطأ
              Text(
                isConnectionError 
                  ? 'مشكلة في الاتصال'
                  : 'عذراً، حدث خطأ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // رسالة الخطأ
              Text(
                isConnectionError 
                  ? 'تعذر الاتصال بالخادم، تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'
                  : 'حدث خطأ أثناء تشغيل التطبيق. يرجى المحاولة مرة أخرى.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // تفاصيل تقنية للخطأ (فقط في وضع التطوير)
              if (errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // زر إعادة المحاولة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // إعادة تشغيل التطبيق
                    restartApp();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isConnectionError 
                      ? Colors.orange 
                      : Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // زر الخروج من التطبيق
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // الخروج من التطبيق
                    exit(0);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'إغلاق التطبيق',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإعادة تشغيل التطبيق
  void restartApp() {
    // يتم تنفيذ هذا الكود فقط على النظام الأصلي (Android & iOS)
    exit(0); // سيؤدي هذا إلى إنهاء التطبيق، وسيقوم المستخدم بفتحه مرة أخرى
    
    // ملاحظة: هذه ليست الطريقة المثالية لإعادة تشغيل التطبيق،
    // ولكنها أبسط حل متاح في الوقت الحالي.
    // يمكن استخدام packages مثل restart_app في المستقبل.
  }
} 