import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
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

class _AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    
    // Current active index
    final currentIndex = navigationProvider.selectedIndex;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Drawer(
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [const Color(0xFF1E222A), const Color(0xFF161A21)]
                    : [Colors.white, const Color(0xFFF8F9FA)],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // زر الإغلاق المتحرك في أعلى القائمة
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animationController.value * 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _closeDrawer(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ),
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
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _buildProfileSection(context, authProvider),
                        const SizedBox(height: 24),
                        
                        // Main Navigation Section
                        _buildSectionTitle(context, 'القائمة الرئيسية'),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/home.svg',
                          text: 'الرئيسية',
                          isActive: currentIndex == 0,
                          onTap: () => _navigateToTab(context, 0),
                        ),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/search.svg',
                          text: 'البحث',
                          isActive: currentIndex == 1,
                          onTap: () => _navigateToTab(context, 1),
                        ),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/categories.svg',
                          text: 'الأقسام',
                          isActive: currentIndex == 2,
                          onTap: () => _navigateToTab(context, 2),
                        ),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/favorites.svg',
                          text: 'المفضلة',
                          isActive: currentIndex == 3,
                          onTap: () => _navigateToTab(context, 3),
                        ),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/user-settings.svg',
                          text: 'حسابي',
                          isActive: currentIndex == 4,
                          onTap: () => _navigateToTab(context, 4),
                        ),
                        
                        // Features Section (only for authenticated users)
                        if (authProvider.isAuthenticated) ...[
                          const SizedBox(height: 16),
                          _buildSectionTitle(context, 'الخدمات'),
                          _buildNavigationItem(
                            context: context,
                            svgPath: 'assets/icons/group.svg',
                            text: 'جروبات',
                            onTap: () => _navigateToScreen(context, const GroupsScreen()),
                          ),
                          _buildNavigationItem(
                            context: context,
                            svgPath: 'assets/icons/money.svg',
                            text: 'شحن رصيد',
                            onTap: () => _navigateToScreen(context, const WalletScreen()),
                          ),
                          _buildNavigationItem(
                            context: context,
                            svgPath: 'assets/icons/request-money.svg',
                            text: 'طلبات الدفع',
                            onTap: () => _navigateToScreen(context, const PaymentRequestsScreen()),
                          ),
                          _buildNavigationItem(
                            context: context,
                            svgPath: 'assets/icons/booking.svg',
                            text: 'طلبات الحجز',
                            onTap: () => _navigateToScreen(context, const BookingRequestsScreen()),
                          ),
                        ],
                        
                        // Support & Settings Section
                        const SizedBox(height: 16),
                        _buildSectionTitle(context, 'الإعدادات والدعم'),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/settings.svg',
                          text: 'الإعدادات',
                          onTap: () => _navigateToScreen(context, const SettingsScreen()),
                        ),
                        _buildNavigationItem(
                          context: context,
                          svgPath: 'assets/icons/phone.svg',
                          text: 'تواصل معنا',
                          onTap: () => _navigateToScreen(context, const ContactUsScreen()),
                        ),
                      ],
                    ),
                  ),
                  
                  // Dark Mode Toggle - إضافة هنا كعنصر ثابت
                  _buildThemeToggle(context, themeProvider, isDarkMode),
                  
                  // Auth Button Section (Login/Logout)
                  _buildAuthButton(context, authProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProfileSection(BuildContext context, AuthProvider authProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (!authProvider.isAuthenticated) {
      return _buildNotAuthenticatedProfile(context, isDarkMode);
    }
    
    // استخدام FutureBuilder لجلب بيانات المستخدم من Firestore
    return FutureBuilder<UserProfile?>(
      future: FirestoreService().getUserProfile(authProvider.user!.uid),
      builder: (context, snapshot) {
        // في حالة جاري تحميل البيانات
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildProfileSkeleton(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // بيانات المستخدم
        final userProfile = snapshot.data;
        final userName = userProfile?.name.isNotEmpty == true 
            ? userProfile!.name 
            : authProvider.user?.email?.split('@').first ?? 'مرحباً بك';
        final userEmail = userProfile?.email ?? authProvider.user?.email ?? '';
        final avatarUrl = userProfile?.avatarUrl;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              // صورة المستخدم
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 56,
                          height: 56,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => _buildUserInitial(context, userName),
                      )
                    : _buildUserInitial(context, userName),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // بناء حالة عدم تسجيل الدخول
  Widget _buildNotAuthenticatedProfile(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF2E3A59), const Color(0xFF1E2A45)]
                : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'قم بتسجيل الدخول للوصول إلى كافة المزايا',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // بناء حرف اختصار اسم المستخدم
  Widget _buildUserInitial(BuildContext context, String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
  
  // هيكل تحميل معلومات المستخدم
  Widget _buildProfileSkeleton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required BuildContext context,
    required String svgPath,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.7)
        : Colors.black87;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final Animation<double> itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
        );
        
        return FadeTransition(
          opacity: itemAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.2, 0),
              end: Offset.zero,
            ).animate(itemAnimation),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive 
                    ? activeColor.withOpacity(0.15) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: activeColor.withOpacity(0.1),
                  highlightColor: activeColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          svgPath,
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? activeColor : inactiveColor,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'الوضع الليلي',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Switch.adaptive(
              value: isDarkMode,
              onChanged: (_) {
                themeProvider.setTheme(
                  isDarkMode ? ThemeMode.light : ThemeMode.dark,
                );
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: authProvider.isAuthenticated
          ? ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, authProvider),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => _navigateToScreen(context, const LoginScreen()),
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    _closeDrawer(context).then((_) {
      Provider.of<NavigationProvider>(context, listen: false).setIndex(tabIndex);
    });
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    _closeDrawer(context).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }

  Future<void> _closeDrawer(BuildContext context) async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF222831) : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('تأكيد تسجيل الخروج'),
            ],
          ),
          content: Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _closeDrawer(context).then((_) {
                  authProvider.signOut(context);
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );
  }
}
