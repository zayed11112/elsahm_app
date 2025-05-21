import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import '../utils/theme_utils.dart';
import 'themed_card.dart';

/// A widget that demonstrates the theme system
/// This can be used as a reference for how to use the various theme components
class ThemeExampleWidget extends StatelessWidget {
  const ThemeExampleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use theme extension to get context-based theme properties
    final isDarkMode = context.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام التصميم'),
        backgroundColor: isDarkMode ? darkBlue : primarySkyBlue,
      ),
      body: SingleChildScrollView(
        padding: context.defaultPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typography Section
            Text('تصنيفات النصوص', style: context.titleLarge),
            const SizedBox(height: defaultPadding),
            Text('عنوان كبير', style: context.titleLarge),
            Text('عنوان متوسط', style: context.titleMedium),
            Text('عنوان صغير', style: context.titleSmall),
            Text('نص أساسي كبير', style: context.bodyLarge),
            Text('نص أساسي متوسط', style: context.bodyMedium),
            Text('نص أساسي صغير', style: context.bodySmall),
            const Divider(height: defaultPadding * 2),
            
            // Colors Section
            Text('الألوان الأساسية', style: context.titleLarge),
            const SizedBox(height: defaultPadding),
            _buildColorRow('لون أساسي', primarySkyBlue),
            _buildColorRow('لون متمم', accentBlue),
            _buildColorRow('لون داكن', darkBlue),
            _buildColorRow('لون فاتح', lightBlue),
            const Divider(height: defaultPadding * 2),
            
            // Status Colors Section
            Text('ألوان الحالة', style: context.titleLarge),
            const SizedBox(height: defaultPadding),
            _buildColorRow('معلق', pendingColor),
            _buildColorRow('موافق', approvedColor),
            _buildColorRow('مرفوض', rejectedColor),
            _buildColorRow('غير نشط', inactiveColor),
            const Divider(height: defaultPadding * 2),
            
            // Cards Section
            Text('البطاقات', style: context.titleLarge),
            const SizedBox(height: defaultPadding),
            
            // Standard Card
            ThemedCard(
              child: const Text('بطاقة قياسية'),
            ),
            const SizedBox(height: defaultPadding),
            
            // Status Cards
            StatusCard(
              status: 'pending',
              title: 'طلب معلق',
              subtitle: 'في انتظار المراجعة',
              child: const Text('محتوى البطاقة المعلقة'),
              onTap: () => _showMessage(context, 'تم النقر على بطاقة معلقة'),
            ),
            const SizedBox(height: defaultPadding),
            
            StatusCard(
              status: 'approved',
              title: 'طلب تمت الموافقة عليه',
              subtitle: 'تمت الموافقة بتاريخ 30/12/2023',
              child: const Text('محتوى البطاقة الموافق عليها'),
              onTap: () => _showMessage(context, 'تم النقر على بطاقة موافق عليها'),
            ),
            const SizedBox(height: defaultPadding),
            
            StatusCard(
              status: 'rejected',
              title: 'طلب مرفوض',
              subtitle: 'تم الرفض بسبب نقص المعلومات',
              child: const Text('محتوى البطاقة المرفوضة'),
              onTap: () => _showMessage(context, 'تم النقر على بطاقة مرفوضة'),
            ),
            const Divider(height: defaultPadding * 2),
            
            // Buttons Section
            Text('الأزرار', style: context.titleLarge),
            const SizedBox(height: defaultPadding),
            
            // Elevated Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showMessage(context, 'تم النقر على زر مرتفع'),
                child: const Text('زر مرتفع'),
              ),
            ),
            const SizedBox(height: defaultPadding),
            
            // Outlined Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showMessage(context, 'تم النقر على زر محدد'),
                child: const Text('زر محدد'),
              ),
            ),
            const SizedBox(height: defaultPadding),
            
            // Text Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showMessage(context, 'تم النقر على زر نصي'),
                child: const Text('زر نصي'),
              ),
            ),
            const SizedBox(height: defaultPadding),
            
            // Gradient Button
            _buildGradientButton(
              'زر متدرج',
              primaryGradient,
              () => _showMessage(context, 'تم النقر على زر متدرج'),
            ),
            const Divider(height: defaultPadding * 2),
            
            // Form Elements Section
            Text('عناصر النموذج', style: context.titleLarge),
            const SizedBox(height: defaultPadding),
            
            // Text Field
            TextField(
              decoration: ThemeUtils.getInputDecoration(
                labelText: 'حقل نصي',
                hintText: 'أدخل نصًا هنا',
                isDarkMode: isDarkMode,
                prefixIcon: const Icon(Icons.text_fields),
              ),
            ),
            const SizedBox(height: defaultPadding),
            
            // Number Field
            TextField(
              decoration: ThemeUtils.getInputDecoration(
                labelText: 'حقل رقمي',
                hintText: 'أدخل رقمًا هنا',
                isDarkMode: isDarkMode,
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: defaultPadding),
            
            // Error Text Field
            TextField(
              decoration: ThemeUtils.getInputDecoration(
                labelText: 'حقل مع خطأ',
                hintText: 'أدخل نصًا هنا',
                isDarkMode: isDarkMode,
                isError: true,
                errorText: 'هذا الحقل مطلوب',
                prefixIcon: const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Text(label),
          const Spacer(),
          Text('#${color.value.toRadixString(16).toUpperCase().substring(2)}'),
        ],
      ),
    );
  }

  Widget _buildGradientButton(
    String label,
    LinearGradient gradient,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: smallPadding),
      height: 48,
      decoration: ThemeUtils.getGradientButtonDecoration(gradient: gradient),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(buttonBorderRadius),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
} 