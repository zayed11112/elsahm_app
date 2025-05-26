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
  Map<String, bool> _notificationSettings = {};

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
          _notificationSettings = settings;
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
          _notificationSettings = {
            for (var category in _categories) category.key: true
          };
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

  Future<void> _toggleCategoryNotification(String key, bool value) async {
    setState(() {
      _notificationSettings[key] = value;
    });
    
    await _saveNotificationSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Master toggle
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

                // Categories section
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _masterToggle ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: AbsorbPointer(
                      absorbing: !_masterToggle,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isEnabled = _notificationSettings[category.key] ?? true;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isEnabled
                                      ? _getCategoryColor(index).withValues(alpha: 0.1)
                                      : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: isEnabled
                                      ? _getCategoryColor(index)
                                      : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                                ),
                              ),
                              title: Text(
                                category.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEnabled
                                      ? null
                                      : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                ),
                              ),
                              subtitle: Text(
                                category.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isEnabled
                                      ? null
                                      : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                                ),
                              ),
                              trailing: Switch(
                                value: isEnabled,
                                onChanged: (value) => _toggleCategoryNotification(
                                  category.key,
                                  value,
                                ),
                                activeColor: _getCategoryColor(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Info section
                if (_masterToggle)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 0,
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'قد تصلك إشعارات إضافية تتعلق بأمان حسابك وتحديثات النظام الهامة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // دالة لإرجاع لون فريد لكل فئة
  Color _getCategoryColor(int index) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    
    return colors[index % colors.length];
  }
} 