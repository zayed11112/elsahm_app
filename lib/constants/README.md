# نظام التصميم - Elsahm Theme System

## نظرة عامة

يوفر نظام التصميم لتطبيق السهم مجموعة متسقة من الألوان والأنماط والمكونات. تم تصميمه لدعم كل من الوضع الفاتح والداكن، مع التركيز على التصميم الجمالي وسهولة الاستخدام.

## المكونات الرئيسية

1. **ثوابت التصميم** (`constants/theme.dart`):
   - تعريف الألوان الأساسية والثانوية
   - ألوان الحالة (معلق، موافق، مرفوض)
   - قيم التباعد والحجم
   - ظلال وزخارف متسقة

2. **امتدادات السياق** (`extensions/theme_extensions.dart`):
   - توفير وصول سهل لقيم النسق من خلال السياق
   - طرق مساعدة للتحقق من وضع السمة الحالي
   - اختصارات للوصول إلى أنماط النص والألوان

3. **أدوات مساعدة** (`utils/theme_utils.dart`):
   - دوال لإنشاء عناصر واجهة مستخدم متسقة
   - حساب ألوان النص المناسبة بناءً على الخلفية
   - إنشاء ديكورات للبطاقات والأزرار

4. **مكونات نموذجية** (`widgets/*.dart`):
   - بطاقات موضوعية
   - بطاقات الحالة لعرض المعلومات مع مؤشرات الحالة
   - أزرار متدرجة وعناصر واجهة مستخدم مخصصة

## كيفية الاستخدام

### تطبيق السمة

يتم تعريف السمات في ملف `main.dart` وتطبيقها من خلال `ThemeProvider`.

```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    // تعريف سمة داكنة
    final darkTheme = ThemeData(
      // ...
    );

    // تعريف سمة فاتحة
    final lightTheme = ThemeData(
      // ...
    );

    return MaterialApp(
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      // ...
    );
  },
)
```

### استخدام الألوان والأنماط

```dart
// استخدام ألوان السمة مباشرة
Container(
  color: primarySkyBlue,
  child: Text('نص بلون السمة'),
)

// استخدام امتدادات السياق
Container(
  color: context.primaryColor,
  child: Text('نص بلون من السياق', style: context.titleLarge),
)

// استخدام أدوات السمة
Container(
  decoration: ThemeUtils.getCardDecoration(
    isDarkMode: context.isDarkMode,
    withShadow: true,
  ),
  child: Text('بطاقة باستخدام أدوات السمة'),
)
```

### استخدام المكونات الجاهزة

```dart
// بطاقة موضوعية بسيطة
ThemedCard(
  child: Text('بطاقة متوافقة مع السمة'),
)

// بطاقة حالة
StatusCard(
  status: 'approved',
  title: 'طلب موافق عليه',
  subtitle: 'تمت الموافقة بتاريخ 21/5/2023',
  child: Text('محتوى البطاقة'),
)
```

## مثال توضيحي

يمكن الاطلاع على استخدام نظام التصميم في ملف `widgets/theme_example_widget.dart` الذي يعرض جميع عناصر التصميم ويوضح كيفية استخدامها.

## ملاحظات

- يستخدم النظام خط `Tajawal` كخط افتراضي
- تم تصميم النظام لدعم اللغة العربية والإنجليزية
- تم اختيار الألوان لتكون متوافقة مع معايير التباين للوصول 