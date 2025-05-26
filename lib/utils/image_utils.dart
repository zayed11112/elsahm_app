import 'package:logging/logging.dart';

/// أدوات مساعدة للتعامل مع الصور
class ImageUtils {
  static final Logger _logger = Logger('ImageUtils');

  /// تحويل رابط الصورة لاستخدام proxy إذا كان من مصدر خارجي غير مسموح به
  /// يمكن استخدام خدمات مثل ImgProxy أو خدمات مشابهة
  static String getProxyUrl(String originalUrl) {
    // تسجيل للتشخيص
    _logger.fine('تحويل رابط الصورة: $originalUrl');

    // قائمة بالمواقع التي تحتاج إلى proxy
    final needsProxy = ['pikbest.com', 'img.pikbest.com'];

    // التحقق مما إذا كان الرابط من موقع يحتاج إلى proxy
    bool requiresProxy = needsProxy.any(
      (domain) => originalUrl.contains(domain),
    );

    if (requiresProxy) {
      // هناك عدة خيارات للتعامل مع مشكلة CORS:

      // 1. استخدام خدمة imgproxy.net (غير مستحسن للإنتاج، استخدم خدمة مخصصة)
      // return 'https://proxy.duckduckgo.com/iu/?u=${Uri.encodeComponent(originalUrl)}';

      // 2. أو استخدام Cloudinary كـ proxy (تحتاج إلى حساب)
      // return 'https://res.cloudinary.com/YOUR_CLOUD_NAME/image/fetch/$originalUrl';

      // 3. الخيار الأفضل: استخدام خدمة ImgProxy الخاصة بك
      // لأغراض الاختبار، سنستخدم خدمة مجانية (غير مستحسن للإنتاج)
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'https://wsrv.nl/?url=$encodedUrl&default=fallback';
    }

    // إذا كان الرابط من مصدر مسموح به، استخدمه كما هو
    return originalUrl;
  }

  /// التحقق من صحة رابط الصورة
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    // التحقق من امتداد الملف
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    bool hasValidExtension = validExtensions.any(
      (ext) => url.toLowerCase().endsWith(ext),
    );

    // التحقق من بروتوكول HTTP/HTTPS
    bool hasValidProtocol =
        url.startsWith('http://') || url.startsWith('https://');

    return hasValidProtocol && hasValidExtension;
  }
}
