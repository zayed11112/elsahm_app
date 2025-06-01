import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/theme.dart';
import 'help_screen.dart';
import 'privacy_policy_screen.dart';
import 'notifications_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    Provider.of<AuthProvider>(context);
    final isDarkMode =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : lightBackground,
      appBar: AppBar(
        backgroundColor: appBarBlue,
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildSectionHeader(context, 'إعدادات الحساب'),

          _buildSettingItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            subtitle: 'إدارة إعدادات الإشعارات',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              );
            },
          ),

          _buildSectionHeader(context, 'التطبيق'),

          _buildSettingItem(
            context,
            icon:
                isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
            title: isDarkMode ? 'الوضع الفاتح' : 'الوضع الليلي',
            subtitle: 'تغيير مظهر التطبيق',
            onTap: () {
              themeProvider.toggleThemeWithAnimation();
            },
            trailing: Transform.scale(
              scale: 0.9, // Slightly smaller switch
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated container for the switch background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 55,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color:
                          isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment:
                            isDarkMode
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            opacity: !isDarkMode ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.wb_sunny,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                          const Spacer(),
                          AnimatedOpacity(
                            opacity: isDarkMode ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.nightlight_round,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Animated slider
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    right: isDarkMode ? 4 : null,
                    left: isDarkMode ? null : 4,
                    child: GestureDetector(
                      onTap: () => themeProvider.toggleThemeWithAnimation(),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionHeader(context, 'المساعدة والدعم'),

          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'عن التطبيق',
            subtitle: 'معلومات عن إصدار التطبيق',
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: 'المساعدة',
            subtitle: 'الأسئلة الشائعة والمساعدة',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),

          _buildSettingItem(
            context,
            icon: Icons.policy_outlined,
            title: 'سياسة الخصوصية والشروط',
            subtitle: 'قراءة سياسات وشروط الاستخدام',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isDarkMode
                          ? [const Color(0xFF2C3E50), const Color(0xFF1A2533)]
                          : [const Color(0xFFFDFDFD), const Color(0xFFF1F9FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.only(top: 25, bottom: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.8),
                          colorScheme.primary,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // App Logo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_white.png',
                            height: 60,
                            width: 60,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.apps,
                                  size: 60,
                                  color: Colors.blue,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // App Name
                        const Text(
                          'شركة السهم',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // App Slogan
                        const Text(
                          'الرائدة في خدمات التسكين الطلابي',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
                    child: Column(
                      children: [
                        // Version info with icon
                        _buildInfoRow(
                          context,
                          Icons.new_releases_outlined,
                          'إصدار التطبيق',
                          '1.0.0',
                          isDarkMode,
                        ),
                        const SizedBox(height: 12),

                        // Developer info
                        _buildInfoRow(
                          context,
                          Icons.code,
                          'تطوير',
                          'م. اسلام زايد',
                          isDarkMode,
                        ),
                        const SizedBox(height: 12),

                        // Release date
                        _buildInfoRow(
                          context,
                          Icons.calendar_month_outlined,
                          'تاريخ الإصدار',
                          'يناير 2024',
                          isDarkMode,
                        ),

                        const SizedBox(height: 22),

                        // Divider with decorative elements
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      isDarkMode
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'تواصل معنا',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDarkMode
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Social Media Links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              context,
                              FontAwesomeIcons.whatsapp,
                              Colors.green,
                              () => _launchURL(
                                'https://wa.me/201093130120',
                                context,
                              ),
                            ),
                            const SizedBox(width: 20),
                            _buildSocialButton(
                              context,
                              Icons.phone,
                              Colors.green,
                              () => _launchURL('tel:+201093130120', context),
                            ),
                            const SizedBox(width: 20),
                            _buildSocialButton(
                              context,
                              Icons.facebook,
                              const Color(0xFF1877F2),
                              () => _launchURL(
                                'https://facebook.com/elsahm.arish',
                                context,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'جميع الحقوق محفوظة © 2023-2024',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white10 : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Center(child: Icon(icon, color: color, size: 20)),
      ),
    );
  }

  // Method to launch URLs (websites, phone, email)
  void _launchURL(String url, [BuildContext? context]) async {
    // Capture ScaffoldMessenger before async operation
    final scaffoldMessenger =
        context != null ? ScaffoldMessenger.of(context) : null;

    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // Show a snackbar if URL can't be launched
        if (scaffoldMessenger != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح: $url'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Show user-friendly error message
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء محاولة فتح التطبيق المطلوب'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
