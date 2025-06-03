import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

class NotificationCategory {
  final String title;
  final String description;
  final String key;
  final IconData icon;

  const NotificationCategory({
    required this.title,
    required this.description,
    required this.key,
    required this.icon,
  });
}

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _masterToggle = true;
  bool _isLoading = true;

  // تعريف فئات الإشعارات
  final List<NotificationCategory> _categories = [
    const NotificationCategory(
      title: 'إشعارات العقارات الجديدة',
      description: 'إشعارات عند إضافة عقارات جديدة في التطبيق',
      key: 'new_properties',
      icon: Icons.apartment,
    ),
    const NotificationCategory(
      title: 'تحديثات الأسعار',
      description: 'إشعارات عند تغيير أسعار العقارات',
      key: 'price_updates',
      icon: Icons.attach_money,
    ),
    const NotificationCategory(
      title: 'إشعارات المفضلة',
      description: 'إشعارات عند تحديث العقارات المفضلة لديك',
      key: 'favorites',
      icon: Icons.favorite,
    ),
    const NotificationCategory(
      title: 'عروض وخصومات',
      description: 'إشعارات للعروض والخصومات الخاصة',
      key: 'promotions',
      icon: Icons.local_offer,
    ),
    const NotificationCategory(
      title: 'تحديثات النظام',
      description: 'إشعارات هامة متعلقة بنظام التطبيق',
      key: 'system',
      icon: Icons.system_update,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل الإعداد الرئيسي أولاً
      final masterEnabled = prefs.getBool('notifications_master') ?? true;
      
      // تحميل إعدادات كل فئة
      final Map<String, bool> settings = {};
      for (var category in _categories) {
        final isEnabled = prefs.getBool('notifications_${category.key}') ?? true;
        settings[category.key] = isEnabled;
      }

      if (mounted) {
        setState(() {
          _masterToggle = masterEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // تعيين القيم الافتراضية
          _masterToggle = true;
        });
      }
    }
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_$key', value);
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ الإعدادات')),
        );
      }
    }
  }

  Future<void> _toggleMasterNotifications(bool value) async {
    setState(() {
      _masterToggle = value;
    });
    
    await _saveNotificationSetting('master', value);
    
    // إذا تم تعطيل الإشعارات بشكل كامل، يتم عرض رسالة للمستخدم
    if (!value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إيقاف جميع الإشعارات'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976d3),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'إعدادات الإشعارات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Master toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _masterToggle
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _masterToggle
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _masterToggle
                                  ? colorScheme.primary.withValues(alpha: 0.2)
                                  : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              color: _masterToggle
                                  ? colorScheme.primary
                                  : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'جميع الإشعارات',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _masterToggle
                                        ? null
                                        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _masterToggle
                                      ? 'ستصلك إشعارات من التطبيق'
                                      : 'جميع الإشعارات متوقفة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _masterToggle
                                        ? null
                                        : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _masterToggle,
                            onChanged: _toggleMasterNotifications,
                            activeColor: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // System permission button
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.7) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          AppSettings.openAppSettings(type: AppSettingsType.notification);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.app_settings_alt,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إعدادات الإشعارات في الجهاز',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'اضغط هنا لفتح إعدادات التطبيق ومنح صلاحية الإشعارات',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // دالة لإرجاع لون فريد لكل فئة
} 