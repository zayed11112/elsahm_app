import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // لإدارة عمليات التحميل المتأخر
import 'dart:developer' as developer; // DIAGNOSTIC: Added proper logging
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider
import '../services/firestore_service.dart'; // Import FirestoreService
import '../models/user_profile.dart'; // Import UserProfile model
import '../widgets/app_drawer.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import '../constants/theme.dart' as app_theme;
import 'categories_screen.dart';
import 'enhanced_more_screen.dart'; // Import the enhanced MoreScreen
// DIAGNOSTIC: Removed unused dart:math import
import 'wallet_screen.dart'; // Import wallet screen for navigation
import 'login_screen.dart'; // Import LoginScreen
// Import EditProfileScreen

// Placeholder screens - we will create these later

// Removed the placeholder SearchScreen class definition
// Removed the placeholder CategoriesScreen class definition
// Removed the placeholder FavoritesScreen class definition
// Removed the placeholder AccountScreen class definition

class MainNavigationScreen extends StatefulWidget {
  // Remove static instance reference and method
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() {
    final state = MainNavigationScreenState();
    return state;
  }

  // Static method to wrap other screens with the bottom navigation bar
  static Widget wrapWithBottomNav({
    required BuildContext context,
    required Widget child,
    required int selectedIndex,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Choose logo based on theme
    final logoAsset =
        isDarkMode
            ? 'assets/images/logo_dark.webp'
            : 'assets/images/logo_white.webp';

    // Create a scaffold that includes both app bar and bottom navigation bar
    return Scaffold(
      // Include the app bar
      appBar: AppBar(
        title: Image.asset(
          logoAsset,
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Elsahm'); // Fallback text
          },
        ),
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.menu,
                        size: 26,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
        ),
        actions: [
          // User balance display with wallet animation
          Container(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Check if user is authenticated
                if (authProvider.isAuthenticated) {
                  // Navigate to wallet screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletScreen()),
                  );
                } else {
                  // Show auth required dialog
                  _showStaticAuthRequiredDialog(context);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Balance amount and currency
                  if (authProvider.isAuthenticated)
                    StreamBuilder<UserProfile?>(
                      stream: FirestoreService().getUserProfileStream(
                        authProvider.user!.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            child: const CircularProgressIndicator(
                              color: Colors.grey,
                              strokeWidth: 2,
                            ),
                          );
                        }

                        final userBalance = snapshot.data?.balance ?? 0.0;
                        // Convert to int to remove decimals
                        final balanceInt = userBalance.toInt();

                        return Container(
                          margin: EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Price number
                              Text(
                                "$balanceInt",
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              // Currency label below the number
                              Text(
                                "جنية",
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Wallet icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icons/walletelsahm.webp',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to original icon if image fails to load
                          return Icon(
                            Icons.account_balance_wallet,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Home (Index 0)
          final navigationProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navigationProvider.setIndex(0);
          // Return to the main screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        backgroundColor: Colors.white,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: ClipOval(
          child: SizedBox.expand(
            child: Image.asset(
              'assets/icons/homeiconelsahm.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: isDarkMode ? app_theme.darkSurface : app_theme.lightSurface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildStaticNavItem(
              context,
              Icons.search,
              'البحث',
              1,
              selectedIndex,
            ),
            _buildStaticNavItem(
              context,
              Icons.dashboard_outlined,
              'الاقسام',
              2,
              selectedIndex,
            ),
            const SizedBox(width: 40),
            _buildStaticNavItem(
              context,
              Icons.favorite_outline,
              'المفضلة',
              3,
              selectedIndex,
            ),
            _buildStaticNavItem(
              context,
              Icons.more_horiz_outlined,
              'المزيد',
              4,
              selectedIndex,
            ),
          ],
        ),
      ),
    );
  }

  // Static version of _buildNavItem for use in the static wrapper
  static Widget _buildStaticNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int selectedIndex,
  ) {
    final bool isSelected = selectedIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color color =
        isSelected
            ? (isDarkMode ? app_theme.accentBlue : app_theme.primaryBlue)
            : (isDarkMode
                ? app_theme.darkTextTertiary
                : app_theme.lightTextTertiary);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final navigationProvider = Provider.of<NavigationProvider>(
              context,
              listen: false,
            );
            navigationProvider.setIndex(index);
            // Return to the main navigation screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show auth required dialog
  static void _showStaticAuthRequiredDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isDarkMode
                          ? [const Color(0xFF2D3748), const Color(0xFF1A202C)]
                          : [Colors.white, const Color(0xFFF7FAFC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning icon
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'تسجيل الدخول مطلوب',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  Text(
                    'يجب عليك تسجيل الدخول أو إنشاء حساب للوصول إلى المحفظة وإدارة رصيدك',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Login button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  // حالة تحميل البيانات
  bool _isDataLoading = false;
  // DIAGNOSTIC: Removed unused _isProfileChecked field

  // قائمة الشاشات الرئيسية - تم حذف static لمنع المشاكل
  final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Index 0
    SearchScreen(), // Index 1 (Placeholder for Offers)
    CategoriesScreen(fromMainScreen: true), // Index 2
    FavoritesScreen(), // Index 3 (Placeholder for Cart)
    EnhancedMoreScreen(), // Index 4 - Use the enhanced MoreScreen
  ];

  @override
  void initState() {
    super.initState();
    developer.log(
      "==== MainNavigationScreen initState ====",
      name: 'MainNavigation',
    );

    // تأخير تحميل البيانات لتسريع ظهور الواجهة
    _delayDataLoading();
  }

  // تأخير تحميل البيانات
  Future<void> _delayDataLoading() async {
    // تأخير لمدة قصيرة حتى تظهر الواجهة
    await Future.delayed(const Duration(milliseconds: 300));

    // بدء تحميل البيانات
    if (mounted) {
      setState(() {
        _isDataLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to both ThemeProvider and NavigationProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final isDarkMode =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Choose logo based on theme (Swapped as per request)
    final logoAsset =
        isDarkMode
            ? 'assets/images/logo_dark.webp'
            : 'assets/images/logo_white.webp';

    developer.log(
      "Building MainNavigationScreen - Selected index: ${navigationProvider.selectedIndex}",
      name: 'MainNavigation',
    );
    developer.log("Logo asset: $logoAsset", name: 'MainNavigation');
    developer.log("Dark mode: $isDarkMode", name: 'MainNavigation');

    return Scaffold(
      appBar: AppBar(
        // DIAGNOSTIC: Removed dead code by always showing AppBar
        title: Image.asset(
          logoAsset,
          height: 40, // Increased height slightly
          errorBuilder: (context, error, stackTrace) {
            developer.log("Error loading logo: $error", name: 'MainNavigation');
            return const Text('Elsahm'); // Fallback text
          },
        ),
        centerTitle: true, // Center the logo
        leading: Builder(
          builder: (context) => _buildMenuButton(context, isDarkMode),
        ),
        actions: [
          // User balance display with wallet animation
          if (_isDataLoading) // عرض الرصيد فقط بعد تحميل البيانات
            _buildBalanceWidget(context, isDarkMode),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: navigationProvider.selectedIndex, // Use index from provider
        children: _widgetOptions,
      ),
      // Custom Bottom App Bar
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => navigationProvider.setIndex(0), // Navigate to Home (Index 0)
        backgroundColor: Colors.white, // White background for the FAB
        elevation: 4.0, // Add some shadow
        shape: const CircleBorder(), // Ensure it's circular
        mini: false,
        heroTag: "homeButton",
        materialTapTargetSize: MaterialTapTargetSize.padded,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                'assets/icons/homeiconelsahm.webp',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0, // Space around the FAB
        color: isDarkMode ? app_theme.darkSurface : app_theme.lightSurface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute items
          children: <Widget>[
            _buildNavItem(
              context,
              navigationProvider,
              Icons.search,
              'البحث',
              1,
            ), // Search -> Index 1
            _buildNavItem(
              context,
              navigationProvider,
              Icons.dashboard_outlined,
              'الاقسام',
              2,
            ), // Categories -> Index 2
            const SizedBox(width: 40), // Spacer for the FAB notch
            _buildNavItem(
              context,
              navigationProvider,
              Icons.favorite_outline,
              'المفضلة',
              3,
            ), // Favorites -> Index 3
            _buildNavItem(
              context,
              navigationProvider,
              Icons.more_horiz_outlined,
              'المزيد',
              4,
            ), // More -> Index 4
          ],
        ),
      ),
    );
  }

  // Widget to display user balance with wallet animation
  Widget _buildBalanceWidget(BuildContext context, bool isDarkMode) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      margin: EdgeInsets.zero, // Eliminar margen para que esté en el extremo
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Verificar si el usuario está autenticado
          if (authProvider.isAuthenticated) {
            // Si está autenticado, navegar a la pantalla de la billetera
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            );
          } else {
            // Si no está autenticado, mostrar diálogo de requerimiento de inicio de sesión
            _showAuthRequiredDialog(context);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Balance amount and currency (a la izquierda)
            if (authProvider.isAuthenticated)
              StreamBuilder<UserProfile?>(
                stream: FirestoreService().getUserProfileStream(
                  authProvider.user!.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(
                        color: Colors.grey,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final userBalance = snapshot.data?.balance ?? 0.0;
                  // Convertir a entero para eliminar los decimales
                  final balanceInt = userBalance.toInt();

                  return Container(
                    margin:
                        EdgeInsets
                            .zero, // Eliminar el margen para reducir el espacio
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price number (sin decimales)
                        Text(
                          "$balanceInt",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        // Currency label below the number
                        Text(
                          "جنية",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Wallet icon on the right (a la derecha)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/walletelsahm.webp',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_balance_wallet,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar diálogo cuando se requiere autenticación
  void _showAuthRequiredDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isDarkMode
                          ? [const Color(0xFF2D3748), const Color(0xFF1A202C)]
                          : [Colors.white, const Color(0xFFF7FAFC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.1,
                    ), // DIAGNOSTIC: Updated from deprecated withOpacity
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animación de advertencia
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    'تسجيل الدخول مطلوب',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contenido
                  Text(
                    'يجب عليك تسجيل الدخول أو إنشاء حساب للوصول إلى المحفظة وإدارة رصيدك',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón de cancelar
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Botón de inicio de sesión
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar el diálogo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Custom static menu button for better performance
  Widget _buildMenuButton(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(
            alpha: 0.2,
          ), // DIAGNOSTIC: Updated from deprecated withOpacity
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.menu,
              size: 26,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build navigation items to avoid repetition
  Widget _buildNavItem(
    BuildContext context,
    NavigationProvider navigationProvider,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isSelected = navigationProvider.selectedIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color color =
        isSelected
            ? (isDarkMode ? app_theme.accentBlue : app_theme.primaryBlue)
            : (isDarkMode
                ? app_theme.darkTextTertiary
                : app_theme.lightTextTertiary);

    return Expanded(
      // Use Expanded to ensure equal spacing
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigationProvider.setIndex(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4.0,
            ), // Reduced vertical padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 24),
                const SizedBox(
                  height: 2,
                ), // Reduced space between icon and text
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11, // Adjust font size
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
