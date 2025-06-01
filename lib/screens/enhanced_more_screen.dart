import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

// Providers
import '../providers/auth_provider.dart';

// Models & Services
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

// Screens
import 'wallet_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'contact_us_screen.dart';
import 'why_choose_us_screen.dart';
import 'categories_screen.dart';
import 'payment_requests_screen.dart';
import 'groups_screen.dart';
import 'notifications_screen.dart';
import 'complaints_screen.dart';
import 'settings_screen.dart';
import 'booking_requests_screen.dart';

// Enhanced Widgets
import '../widgets/enhanced_card.dart';
import '../widgets/enhanced_button.dart';
import '../widgets/enhanced_loading.dart';

// Constants & Extensions
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

/// Enhanced More Screen with professional design and optimized performance
class EnhancedMoreScreen extends StatefulWidget {
  const EnhancedMoreScreen({super.key});

  @override
  State<EnhancedMoreScreen> createState() => _EnhancedMoreScreenState();
}

class _EnhancedMoreScreenState extends State<EnhancedMoreScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger('EnhancedMoreScreen');
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserProfile? userProfile;
  bool isLoading = false;
  int unreadNotificationsCount = 0;
  StreamSubscription? _notificationCountSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
    _checkForUnreadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationCountSubscription?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: normalAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        userProfile = await _firestoreService.getUserProfile(
          authProvider.user!.uid,
        );
      }
    } catch (error) {
      _logger.warning('Error loading profile: $error');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _checkForUnreadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        _notificationCountSubscription?.cancel();

        _notificationCountSubscription = _notificationService
            .getUnreadNotificationsCount(authProvider.user!.uid)
            .listen(
              (count) {
                if (mounted) {
                  setState(() => unreadNotificationsCount = count);
                }
              },
              onError: (error) {
                _logger.warning('خطأ في تحميل عدد الإشعارات: $error');
                if (mounted) {
                  setState(() => unreadNotificationsCount = 0);
                }
              },
            );
      } catch (e) {
        _logger.severe('استثناء في عداد الإشعارات: $e');
        if (mounted) {
          setState(() => unreadNotificationsCount = 0);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = context.isDarkMode;
    final isLoggedIn = authProvider.user != null;

    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : lightBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child:
              isLoggedIn
                  ? _buildLoggedInView(context, authProvider.user!.uid)
                  : _buildGuestView(context),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, String userId) {
    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.getUserProfileStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: EnhancedLoading(
              style: LoadingStyle.circular,
              message: 'جاري تحميل البيانات...',
              showMessage: true,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorView(context, snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyView(context);
        }

        final userProfile = snapshot.data!;
        return _buildMainContent(context, userProfile, true);
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return _buildMainContent(context, null, false);
  }

  Widget _buildMainContent(
    BuildContext context,
    UserProfile? userProfile,
    bool isLoggedIn,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader(context, userProfile, isLoggedIn),
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (isLoggedIn && userProfile != null) ...[
                const SizedBox(height: defaultPadding),
                _buildUserDetailsCard(context, userProfile),
                const SizedBox(height: defaultPadding),
                _buildEditProfileButton(context, userProfile),
                const SizedBox(height: defaultPadding),
                _buildWalletCard(context, userProfile),
              ] else ...[
                const SizedBox(height: largePadding),
                _buildLoginPrompt(context),
              ],
              const SizedBox(height: defaultPadding),
              _buildServicesGrid(context, isLoggedIn),
              const SizedBox(height: defaultPadding),
              if (isLoggedIn)
                _buildLogoutButton(context)
              else
                _buildLoginButton(context),
              const SizedBox(height: largePadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    final isDarkMode = context.isDarkMode;

    return Center(
      child: EnhancedCard(
        margin: const EdgeInsets.all(defaultPadding),
        child: Padding(
          padding: const EdgeInsets.all(largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: errorColor),
              const SizedBox(height: defaultPadding),
              Text(
                'حدث خطأ',
                style: context.titleLarge?.copyWith(
                  color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: smallPadding),
              Text(
                error,
                style: context.bodyMedium?.copyWith(
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: defaultPadding),
              PrimaryButton(
                text: 'إعادة المحاولة',
                onPressed: () => _loadUserProfile(),
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return Center(
      child: EnhancedCard(
        margin: const EdgeInsets.all(defaultPadding),
        child: Padding(
          padding: const EdgeInsets.all(largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: isDarkMode ? darkTextTertiary : lightTextTertiary,
              ),
              const SizedBox(height: defaultPadding),
              Text(
                'لم يتم العثور على الملف الشخصي',
                style: context.titleMedium?.copyWith(
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserProfile? userProfile,
    bool isLoggedIn,
  ) {
    final isDarkMode = context.isDarkMode;

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDarkMode
                      ? [
                        primaryBlue.withValues(alpha: 0.8),
                        secondaryTeal.withValues(alpha: 0.6),
                      ]
                      : [primaryBlue, secondaryTeal],
            ),
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned.fill(
                child: CustomPaint(painter: _HeaderPatternPainter()),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: defaultPadding),
                      if (isLoggedIn && userProfile != null)
                        _buildUserHeader(context, userProfile)
                      else
                        _buildGuestHeader(context),
                      const Spacer(),
                      _buildHeaderActions(context, isLoggedIn),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, UserProfile userProfile) {
    return Column(
      children: [
        // Profile Image
        Hero(
          tag: 'profile_image',
          child: GestureDetector(
            onTap: () => _viewProfileImage(context, userProfile.avatarUrl),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    userProfile.avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: userProfile.avatarUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const EnhancedLoading(
                                style: LoadingStyle.circular,
                                size: 30,
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade600,
                          ),
                        ),
              ),
            ),
          ),
        ),

        const SizedBox(height: defaultPadding),

        // User Name
        Text(
          userProfile.name.isNotEmpty ? userProfile.name : userProfile.email,
          style: context.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: smallPadding),

        // User Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            userProfile.status.isNotEmpty ? userProfile.status : 'مستخدم',
            style: context.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(
            Icons.person_outline,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: defaultPadding),

        Text(
          'مرحباً بك',
          style: context.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        const SizedBox(height: smallPadding),

        Text(
          'قم بتسجيل الدخول للوصول لجميع الميزات',
          style: context.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHeaderActions(BuildContext context, bool isLoggedIn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Complaints Icon
        _buildHeaderActionButton(
          context,
          Icons.contact_support_outlined,
          'الشكاوى',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
          ),
        ),

        // Notifications Icon
        _buildHeaderActionButton(
          context,
          Icons.notifications_outlined,
          'الإشعارات',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ),
          badge: unreadNotificationsCount > 0 ? unreadNotificationsCount : null,
        ),

        // Settings Icon
        _buildHeaderActionButton(
          context,
          Icons.settings_outlined,
          'الإعدادات',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    int? badge,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            if (badge != null && badge > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: errorColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge > 9 ? '9+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewProfileImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Hero(
                    tag: 'profile_image',
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) => const Center(
                            child: EnhancedLoading(
                              style: LoadingStyle.circular,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildUserDetailsCard(BuildContext context, UserProfile userProfile) {
    final isDarkMode = context.isDarkMode;

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: smallPadding),
                Text(
                  'بيانات الحساب',
                  style: context.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            _buildDetailRow(context, 'الحالة', userProfile.status),
            _buildDetailRow(context, 'رقم الطالب', userProfile.studentId),
            _buildDetailRow(context, 'الكلية', userProfile.faculty),
            _buildDetailRow(context, 'الفرع', userProfile.branch),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDarkMode = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: context.bodyMedium?.copyWith(
                color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'غير محدد',
              style: context.bodyMedium?.copyWith(
                color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(
    BuildContext context,
    UserProfile userProfile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: PrimaryButton(
        text: 'تعديل بياناتي',
        icon: Icons.edit_outlined,
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EditProfileScreen(userProfile: userProfile),
              ),
            ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, UserProfile userProfile) {
    final isDarkMode = context.isDarkMode;

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDarkMode
                ? [
                  primaryBlue.withValues(alpha: 0.2),
                  secondaryTeal.withValues(alpha: 0.1),
                ]
                : [
                  primaryBlue.withValues(alpha: 0.1),
                  secondaryTeal.withValues(alpha: 0.05),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'المحفظة الأساسية',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'نشطة',
                    style: context.bodySmall?.copyWith(
                      color: successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDarkMode
                          ? [
                            darkCard.withValues(alpha: 0.8),
                            darkCard.withValues(alpha: 0.6),
                          ]
                          : [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.7),
                          ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: primaryBlue.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الرصيد المتاح',
                        style: context.bodyMedium?.copyWith(
                          color:
                              isDarkMode
                                  ? darkTextSecondary
                                  : lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        userProfile.balance.toStringAsFixed(2),
                        style: context.titleLarge?.copyWith(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'جنيه مصري',
                        style: context.bodyMedium?.copyWith(
                          color:
                              isDarkMode
                                  ? darkTextSecondary
                                  : lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildWalletActionButton(
                    context,
                    title: 'شحن المحفظة',
                    icon: Icons.add_circle_outline,
                    color: primaryBlue,
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletScreen(),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: _buildWalletActionButton(
                    context,
                    title: 'تاريخ المعاملات',
                    icon: Icons.history_outlined,
                    color: secondaryTeal,
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentRequestsScreen(),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Custom wallet action button with enhanced design
  Widget _buildWalletActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = context.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.15),
          highlightColor: color.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: context.bodyMedium?.copyWith(
                      color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDarkMode
                ? [
                  primaryBlue.withValues(alpha: 0.1),
                  secondaryTeal.withValues(alpha: 0.05),
                ]
                : [
                  primaryBlue.withValues(alpha: 0.05),
                  secondaryTeal.withValues(alpha: 0.03),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // أيقونة تسجيل الدخول المحسنة
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue.withValues(alpha: 0.15),
                    secondaryTeal.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.login_outlined, size: 40, color: primaryBlue),
            ),
            const SizedBox(height: 20),

            // العنوان
            Text(
              'قم بتسجيل الدخول',
              style: context.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),

            // الوصف
            Text(
              'للوصول إلى جميع الميزات والخدمات المتاحة',
              style: context.bodyMedium?.copyWith(
                color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // زر تسجيل الدخول الاحترافي
            _buildEnhancedLoginButton(context),
          ],
        ),
      ),
    );
  }

  /// Enhanced login button with professional design
  Widget _buildEnhancedLoginButton(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            primaryBlue,
            primaryBlue.withValues(alpha: 0.9),
            secondaryTeal,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: secondaryTeal.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة تسجيل الدخول
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.login_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // نص الزر
                Expanded(
                  child: Text(
                    'تسجيل الدخول',
                    style: context.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // سهم التوجيه
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context, bool isLoggedIn) {
    final isDarkMode = context.isDarkMode;

    final services = [
      ServiceItem(
        icon: Icons.favorite_border,
        title: 'المفضلة',
        subtitle: 'العقارات المحفوظة',
        color: secondaryPurple,
        requiresAuth: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
      ),
      ServiceItem(
        icon: Icons.place_outlined,
        title: 'الأماكن المتاحة',
        subtitle: 'استعراض العقارات',
        color: secondaryTeal,
        requiresAuth: false,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const CategoriesScreen(
                      fromMainScreen: false,
                      scrollToAvailablePlaces: true,
                    ),
              ),
            ),
      ),
      ServiceItem(
        icon: Icons.category_outlined,
        title: 'الأقسام',
        subtitle: 'تصفح حسب الفئة',
        color: secondaryOrange,
        requiresAuth: false,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const CategoriesScreen(
                      fromMainScreen: false,
                      scrollToAvailablePlaces: false,
                    ),
              ),
            ),
      ),
      ServiceItem(
        icon: Icons.support_agent_outlined,
        title: 'الشكاوى',
        subtitle: 'تقديم شكوى أو استفسار',
        color: warningColor,
        requiresAuth: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
            ),
      ),
      ServiceItem(
        icon: Icons.request_page_outlined,
        title: 'طلبات الدفع',
        subtitle: 'متابعة المدفوعات',
        color: successColor,
        requiresAuth: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentRequestsScreen(),
              ),
            ),
      ),
      ServiceItem(
        icon: Icons.bookmark_outline,
        title: 'طلبات الحجز',
        subtitle: 'إدارة الحجوزات',
        color: primaryBlue,
        requiresAuth: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookingRequestsScreen(),
              ),
            ),
      ),
      ServiceItem(
        icon: Icons.groups_outlined,
        title: 'المجموعات',
        subtitle: 'انضم للمجموعات',
        color: secondaryPurple,
        requiresAuth: false,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupsScreen()),
            ),
      ),
      ServiceItem(
        icon: Icons.vpn_key_outlined,
        title: 'تغيير كلمة المرور',
        subtitle: 'تحديث كلمة المرور',
        color: errorColor,
        requiresAuth: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            ),
      ),
      ServiceItem(
        icon: Icons.phone_outlined,
        title: 'اتصل بنا',
        subtitle: 'تواصل مع الدعم',
        color: infoColor,
        requiresAuth: false,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactUsScreen()),
            ),
      ),
      ServiceItem(
        icon: Icons.info_outline,
        title: 'عن السهم',
        subtitle: 'معلومات التطبيق',
        color: primaryBlue,
        requiresAuth: false,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WhyChooseUsScreen(),
              ),
            ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            children: [
              Icon(
                Icons.apps_outlined,
                color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                size: 20,
              ),
              const SizedBox(width: smallPadding),
              Text(
                'الخدمات المتاحة',
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${services.length} خدمة',
                  style: context.bodySmall?.copyWith(
                    color: primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: defaultPadding,
            mainAxisSpacing: defaultPadding,
            childAspectRatio: 1.0, // نسبة مربعة لعرض أفضل للنصوص والأيقونات
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceCard(context, service, isLoggedIn);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceItem service,
    bool isLoggedIn,
  ) {
    final isDarkMode = context.isDarkMode;
    final canAccess = !service.requiresAuth || isLoggedIn;

    return EnhancedCard(
      onTap:
          canAccess
              ? () {
                HapticFeedback.lightImpact();
                service.onTap();
              }
              : () => _showLoginRequiredDialog(context),
      enableHoverEffect: true,
      enablePressEffect: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة الخدمة
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color:
                    canAccess
                        ? service.color.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      canAccess
                          ? service.color.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow:
                    canAccess
                        ? [
                          BoxShadow(
                            color: service.color.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                service.icon,
                color: canAccess ? service.color : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // عنوان الخدمة - يظهر دائماً
            Text(
              service.title,
              style: context.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    canAccess
                        ? (isDarkMode ? darkTextPrimary : lightTextPrimary)
                        : (isDarkMode ? darkTextSecondary : lightTextSecondary),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // وصف الخدمة - يظهر دائماً
            Text(
              service.subtitle,
              style: context.bodySmall?.copyWith(
                color:
                    canAccess
                        ? (isDarkMode ? darkTextSecondary : lightTextSecondary)
                        : (isDarkMode
                            ? darkTextSecondary.withValues(alpha: 0.7)
                            : lightTextSecondary.withValues(alpha: 0.7)),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // أيقونة القفل للخدمات المحمية
            if (!canAccess) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'مطلوب تسجيل دخول',
                      style: context.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: PrimaryButton(
        text: 'تسجيل الدخول',
        icon: Icons.login,
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: DangerButton(
        text: 'تسجيل الخروج',
        icon: Icons.logout,
        onPressed: () => _showLogoutDialog(context),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تسجيل الدخول مطلوب'),
            content: const Text('يجب تسجيل الدخول للوصول إلى هذه الخدمة'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.signOut();
                },
                style: ElevatedButton.styleFrom(backgroundColor: errorColor),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
    );
  }
}

/// Service Item Model
class ServiceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool requiresAuth;
  final VoidCallback onTap;

  const ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.requiresAuth,
    required this.onTap,
  });
}

/// Header Pattern Painter
class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 30, paint);

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 20, paint);

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
