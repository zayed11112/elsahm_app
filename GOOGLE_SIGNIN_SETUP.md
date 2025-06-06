# إعداد تسجيل الدخول بـ Google للنسخة Release

## المشكلة
تسجيل الدخول بـ Google يعمل في نسخة Debug لكن لا يعمل في نسخة Release.

## السبب
نسخة Release تستخدم keystore مختلف عن نسخة Debug، وبالتالي تحتاج SHA-1 fingerprint مختلف.

## الحل

### 1. SHA-1 Fingerprints المطلوبة:

**Debug SHA-1:**
```
D1:81:0C:E8:5E:4F:5C:57:5C:6F:3A:D9:EF:82:40:CD:46:2C:76:8F
```

**Release SHA-1:**
```
F3:D6:8E:57:40:04:92:65:59:37:CD:C0:4F:68:06:CD:D8:2C:76:24
```

### 2. خطوات إضافة SHA-1 إلى Firebase Console:

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروع `elsahm-app`
3. اذهب إلى Project Settings (⚙️)
4. في تبويب "General"، ابحث عن تطبيق Android
5. اضغط على "Add fingerprint"
6. أضف SHA-1 fingerprint للـ Release:
   ```
   F3:D6:8E:57:40:04:92:65:59:37:CD:C0:4F:68:06:CD:D8:2C:76:24
   ```
7. احفظ التغييرات
8. حمّل ملف `google-services.json` الجديد
9. استبدل الملف الموجود في `android/app/google-services.json`

### 3. التحقق من الإعدادات:

بعد إضافة SHA-1 fingerprint، تأكد من:
- ✅ تم إضافة كلاً من Debug و Release SHA-1
- ✅ تم تحديث ملف google-services.json
- ✅ تم إعادة بناء التطبيق

### 4. اختبار التطبيق:

```bash
# بناء نسخة release
flutter build apk --release

# تثبيت التطبيق على الجهاز
flutter install --release
```

### 5. ملاحظات مهمة:

- SHA-1 fingerprint حساس للحالة (case-sensitive)
- يجب إضافة SHA-1 لكل keystore تستخدمه
- في حالة تغيير keystore، يجب إضافة SHA-1 الجديد
- تأكد من أن package name صحيح: `com.example.elsahm_app`

### 6. استكشاف الأخطاء:

إذا استمرت المشكلة:
1. تأكد من صحة SHA-1 fingerprint
2. تأكد من تحديث google-services.json
3. امسح cache التطبيق: `flutter clean`
4. أعد بناء التطبيق: `flutter build apk --release`
5. تحقق من logs التطبيق للأخطاء

### 7. الملفات المحدثة:

- ✅ `android/app/proguard-rules.pro` - إضافة قواعد Google Sign In
- ✅ `lib/providers/auth_provider.dart` - تحسين معالجة الأخطاء
- ⚠️ `android/app/google-services.json` - يحتاج تحديث من Firebase Console

## الخطوة التالية:
قم بإضافة SHA-1 fingerprint إلى Firebase Console وحمّل ملف google-services.json الجديد.
