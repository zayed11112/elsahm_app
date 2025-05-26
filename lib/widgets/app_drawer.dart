import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add SVG support

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
// Import screens for navigation (adjust paths if needed)
import '../screens/contact_us_screen.dart';
import '../screens/login_screen.dart'; // أضف استيراد شاشة تسجيل الدخول
import '../screens/payment_requests_screen.dart'; // Import payment requests screen
import '../screens/wallet_screen.dart'; // Import wallet screen
import '../screens/settings_screen.dart'; // Import the new settings screen
import '../screens/groups_screen.dart'; // Import groups screen
import '../screens/booking_requests_screen.dart'; // Import booking requests screen
// import '../screens/settings_screen.dart'; // Placeholder for settings

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  // إضافة متحكم الرسوم المتحركة للقائمة
  late AnimationController _animationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _drawerFadeAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد متحكم الرسوم المتحركة
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // إنشاء تأثير الانزلاق من اليسار
    _drawerSlideAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // إنشاء تأثير التدرج للظهور
    _drawerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // تشغيل التأثير عند فتح القائمة
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Drawer(
          elevation: 10,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_drawerSlideAnimation.value, 0),
              end: Offset.zero,
            ).animate(_animationController),
            child: FadeTransition(
              opacity: _drawerFadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors:
                        isDarkMode
                            ? [const Color(0xFF222831), const Color(0xFF1A1C24)]
                            : [
                              const Color(0xFFF5F5F5),
                              const Color(0xFFE0E0E0),
                            ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    SizedBox(height: 80),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/home.svg',
                      text: 'الرئيسية',
                      onTap: () => _navigateToTab(context, 0),
                    ),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/search.svg',
                      text: 'البحث',
                      onTap: () => _navigateToTab(context, 1),
                    ),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/categories.svg',
                      text: 'الأقسام',
                      onTap: () => _navigateToTab(context, 2),
                    ),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/favorites.svg',
                      text: 'المفضلة',
                      onTap: () => _navigateToTab(context, 3),
                    ),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/group.svg',
                      text: 'جروبات',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupsScreen(),
                          ),
                        );
                      },
                    ),
                    if (authProvider.isAuthenticated) ...[
                      _buildDrawerItem(
                        svgPath: 'assets/icons/money.svg',
                        text: 'شحن رصيد',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        svgPath: 'assets/icons/request-money.svg',
                        text: 'طلبات الدفع',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentRequestsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        svgPath: 'assets/icons/booking.svg',
                        text: 'طلبات الحجز',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingRequestsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    _buildDrawerItem(
                      svgPath: 'assets/icons/user-settings.svg',
                      text: 'حسابي',
                      onTap: () => _navigateToTab(context, 4),
                    ),
                    Divider(
                      color: Theme.of(context).dividerColor,
                      thickness: 0.8,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/settings.svg',
                      text: 'الإعدادات',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final Animation<double> itemAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.5,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        );

                        return FadeTransition(
                          opacity: itemAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.3, 0),
                              end: Offset.zero,
                            ).animate(itemAnimation),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 4.0,
                              ),
                              title: Center(
                                child: Text(
                                  'الوضع الليلي',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              subtitle: Center(
                                child: Text(
                                  'تغيير مظهر التطبيق',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              leading: Switch(
                                value: isDarkMode,
                                onChanged: (_) {
                                  themeProvider.setTheme(
                                    isDarkMode
                                        ? ThemeMode.light
                                        : ThemeMode.dark,
                                  );
                                },
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isDarkMode
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      svgPath: 'assets/icons/phone.svg',
                      text: 'تواصل معنا',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: Theme.of(context).dividerColor,
                      thickness: 0.8,
                      indent: 20,
                      endIndent: 20,
                    ),
                    if (authProvider.isAuthenticated)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final Animation<double> itemAnimation =
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(
                                  0.6,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              );

                          return FadeTransition(
                            opacity: itemAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-0.3, 0),
                                end: Offset.zero,
                              ).animate(itemAnimation),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 12.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade500,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final navigator = Navigator.of(context);
                                        await _animationController.reverse();
                                        if (mounted) {
                                          navigator.pop();
                                        }
                                        await authProvider.signOut();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 16.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.logout_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  'تسجيل الخروج',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final Animation<double> itemAnimation =
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(
                                  0.6,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              );

                          return FadeTransition(
                            opacity: itemAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-0.3, 0),
                                end: Offset.zero,
                              ).animate(itemAnimation),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    await _animationController.reverse();
                                    if (mounted) {
                                      navigator.pop();
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded),
                                      SizedBox(width: 8),
                                      Text(
                                        'تسجيل الدخول',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Método simplificado para elementos del drawer
  Widget _buildDrawerItem({
    IconData? icon,
    String? svgPath,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // تأخير ظهور كل عنصر قائمة قليلاً عن الآخر
            final double delayFactor = 0.3;
            final Animation<double> itemAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(delayFactor, 1.0, curve: Curves.easeOut),
              ),
            );

            return FadeTransition(
              opacity: itemAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(itemAnimation),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading:
                      svgPath != null
                          ? SizedBox(
                            width: 28,
                            height: 28,
                            child: SvgPicture.asset(svgPath),
                          )
                          : Icon(
                            icon ?? Icons.circle,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            size: 28,
                          ),
                  title: Center(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  onTap: () {
                    // تأثير إغلاق متحرك
                    _animationController.reverse().then((_) {
                      onTap();
                    });
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    _animationController.reverse().then((_) {
      Navigator.pop(context);
      Provider.of<NavigationProvider>(
        context,
        listen: false,
      ).setIndex(tabIndex);
    });
  }
}
