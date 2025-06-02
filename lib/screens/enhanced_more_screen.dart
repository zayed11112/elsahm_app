import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marquee_widget/marquee_widget.dart';

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
        // Profile Image - changed from icon to image
        Container(
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
            child: Image.asset(
              'assets/images/su.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person_outline,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
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
          () {
            if (isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
              );
            } else {
              _showLoginRequiredDialog(context);
            }
          },
        ),

        // Notifications Icon
        _buildHeaderActionButton(
          context,
          Icons.notifications_outlined,
          'الإشعارات',
          () {
            if (isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            } else {
              _showLoginRequiredDialog(context);
            }
          },
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
    
    // Check if all user profile fields are empty
    final bool allFieldsEmpty = userProfile.status.isEmpty &&
        userProfile.studentId.isEmpty &&
        userProfile.phoneNumber.isEmpty &&
        userProfile.faculty.isEmpty &&
        userProfile.branch.isEmpty;
    
    // If all fields are empty, show a prompt message instead of the details card
    if (allFieldsEmpty) {
      return EnhancedCard(
        margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title with right alignment
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                children: [
                  Text(
                    'بيانات الحساب',
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: smallPadding),
                  Icon(
                    Icons.person_outline,
                    color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding * 1.5),
              
              // Empty profile info icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 32,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: defaultPadding),
              
              // Bold message text
              Text(
                "اضغط علي زر تعديل بياناتي بالأسفل وادخل بياناتك حتي تتمتع بتجربة مميزة",
                style: context.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise show the normal details card with available information
    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with right alignment
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                Text(
                  'بيانات الحساب',
                  style: context.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                  ),
                ),
                const SizedBox(width: smallPadding),
                Icon(
                  Icons.person_outline,
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            _buildDetailRow(
              context,
              'الحالة',
              userProfile.status,
              Icons.person_pin_circle_outlined,
            ),
            _buildDetailRow(
              context,
              'رقم الطالب',
              userProfile.studentId,
              Icons.badge_outlined,
            ),
            _buildDetailRow(
              context,
              'رقم الهاتف',
              userProfile.phoneNumber,
              Icons.phone_outlined,
            ),
            _buildDetailRow(
              context,
              'الكلية',
              userProfile.faculty,
              Icons.school_outlined,
            ),
            _buildDetailRow(
              context,
              'الفرع',
              userProfile.branch,
              Icons.location_city_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    // If the value is empty, return an empty container (effectively hiding this row)
    if (value.isEmpty) {
      return Container();
    }
    
    final isDarkMode = context.isDarkMode;
    final primaryColor = isDarkMode ? skyBlue : const Color(0xFF1976d3);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        children: [
          // Value aligned to the left
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: context.bodyMedium?.copyWith(
                color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Label aligned to the right with icon
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: context.bodyMedium?.copyWith(
                    color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: primaryColor, size: 18),
              ],
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
    final isDarkMode = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        children: [
          PrimaryButton(
            text: 'تعديل بياناتي',
            icon: Icons.edit_outlined,
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            EditProfileScreen(userProfile: userProfile),
                  ),
                ),
          ),
          // Add note below the button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color:
                      isDarkMode
                          ? skyBlue.withOpacity(0.7)
                          : const Color(0xFF1976d3).withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  "اضغط علي الزر لتغير بياناتك بسهولة",
                  style: TextStyle(
                    color:
                        isDarkMode ? darkTextSecondary : Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/icons/walletelsahm.webp',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_balance_wallet_outlined,
                              color: primaryBlue,
                              size: 20,
                            );
                          },
                        ),
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
                        userProfile.balance == userProfile.balance.toInt()
                            ? userProfile.balance.toInt().toString()
                            : userProfile.balance.toStringAsFixed(2),
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
                    title: 'شحن الرصيد',
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
                    title: 'سجل المعاملات',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 360; // Check if screen is wide enough

    // Text style for wallet buttons
    final TextStyle textStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black87,
      fontWeight: FontWeight.w700,
      fontSize: 15.5,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 65, // Increased height for better touch area
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2A36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),

                // Always use Marquee text for wallet buttons
                Expanded(
                  child: SizedBox(
                    height: 24, // Fixed height for consistent animation
                    child: Marquee(
                      animationDuration: const Duration(seconds: 2),
                      backDuration: const Duration(milliseconds: 1000),
                      pauseDuration: const Duration(milliseconds: 1000),
                      direction: Axis.horizontal,
                      textDirection: TextDirection.rtl,
                      autoRepeat: true,
                      child: Text(
                        title,
                        style: textStyle,
                      ),
                    ),
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
        subtitle: '',
        color: primaryBlue,
        requiresAuth: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
      ),
      ServiceItem(
        icon: Icons.place_outlined,
        title: 'الاماكن المتاحة',
        subtitle: '',
        color: primaryBlue,
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
        title: 'الاقسام',
        subtitle: '',
        color: primaryBlue,
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
        subtitle: '',
        color: primaryBlue,
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
        subtitle: '',
        color: primaryBlue,
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
        subtitle: '',
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
        title: 'جروبات',
        subtitle: '',
        color: primaryBlue,
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
        subtitle: '',
        color: primaryBlue,
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
        icon: Icons.info_outline,
        title: 'عن السهم',
        subtitle: '',
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
      ServiceItem(
        icon: Icons.phone_outlined,
        title: 'اتصل بنا',
        subtitle: '',
        color: primaryBlue,
        requiresAuth: false,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactUsScreen()),
            ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2A36).withOpacity(0.7) : const Color(0xFFEDF4FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Grid view icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? darkBackground.withOpacity(0.6) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: primaryBlue,
                  ),
                ),
                // Title moved to the right side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الخدمات المتاحة',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                      ),
                    ),
                    Text(
                      'جميع الخدمات في مكان واحد',
                      style: context.bodySmall?.copyWith(
                        color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Services grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(defaultPadding, 0, defaultPadding, defaultPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: defaultPadding,
              mainAxisSpacing: defaultPadding,
              childAspectRatio: 2.8, // Wider card for the new design
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(context, service, isLoggedIn);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceItem service,
    bool isLoggedIn,
  ) {
    final isDarkMode = context.isDarkMode;
    final canAccess = !service.requiresAuth || isLoggedIn;
    // Check if title is long and needs marquee effect
    final bool isLongText = service.title.length > 10;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAccess
            ? () {
                HapticFeedback.lightImpact();
                service.onTap();
              }
            : () => _showLoginRequiredDialog(context),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Service icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  service.icon,
                  color: canAccess ? primaryBlue : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Service title - using exactly the same approach as in home_screen.dart
              Expanded(
                child: Container(
                  height: 22.0,
                  alignment: Alignment.centerRight,
                  child: isLongText
                    ? Marquee(
                        animationDuration: const Duration(seconds: 2),
                        backDuration: const Duration(milliseconds: 1000),
                        pauseDuration: const Duration(milliseconds: 1000),
                        direction: Axis.horizontal,
                        textDirection: TextDirection.rtl,
                        autoRepeat: true,
                        child: Text(
                          service.title,
                          style: context.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                            color: canAccess
                              ? (isDarkMode ? darkTextPrimary : lightTextPrimary)
                              : (isDarkMode ? darkTextSecondary : lightTextSecondary),
                          ),
                        ),
                      )
                    : Text(
                        service.title,
                        style: context.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                          color: canAccess
                            ? (isDarkMode ? darkTextPrimary : lightTextPrimary)
                            : (isDarkMode ? darkTextSecondary : lightTextSecondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                ),
              ),
              
              // Lock icon for auth-required services
              if (!canAccess)
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
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
    final isDarkMode = context.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF5963),
                  const Color(0xFFFF7B7B),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5963).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'تسجيل الخروج',
                  style: context.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A2A36) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, primaryBlue.withOpacity(0.7)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'تسجيل الدخول مطلوب',
                          style: context.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'يجب تسجيل الدخول للوصول إلى هذه الخدمة والاستفادة من جميع مميزات التطبيق',
                          style: context.bodyMedium?.copyWith(
                            color:
                                isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'إلغاء',
                                      style: context.titleSmall?.copyWith(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Login Button
                            Expanded(
                              flex: 2,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryBlue, secondaryTeal],
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryBlue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.login,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'تسجيل الدخول',
                                          style: context.titleSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A2A36) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF5963),
                      const Color(0xFFFF7B7B),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'تسجيل الخروج',
                      style: context.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
                      style: context.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'إلغاء',
                                  style: context.titleSmall?.copyWith(
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Logout Button
                        Expanded(
                          flex: 2,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop();
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                await authProvider.signOut(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF5963),
                                      const Color(0xFFFF7B7B),
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5963).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تسجيل الخروج',
                                      style: context.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

/// Custom MarqueeText widget for scrolling text
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Axis scrollAxis;
  final double velocity;
  final Duration startAfter;
  final Duration pauseAfterRound;
  final int roundsBeforePause;
  final bool showFading;

  const MarqueeText({
    Key? key,
    required this.text,
    required this.style,
    this.scrollAxis = Axis.horizontal,
    this.velocity = 40.0,
    this.startAfter = const Duration(seconds: 1),
    this.pauseAfterRound = const Duration(seconds: 1),
    this.roundsBeforePause = 1,
    this.showFading = true,
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late Animation<double> _animation;
  late AnimationController _animationController;
  double _contentSize = 0;
  bool _hasOverflow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Check if text overflows its container
      _hasOverflow = _scrollController.position.maxScrollExtent > 0;
      _contentSize = _scrollController.position.extentTotal;

      if (_hasOverflow) {
        _startMarquee();
      }
    });
  }

  void _startMarquee() {
    _timer?.cancel();
    _timer = Timer(widget.startAfter, () {
      if (mounted && _hasOverflow) {
        _animationController.stop();
        _animationController.reset();

        // Calculate the animation duration based on content size and velocity
        final totalDistance = _contentSize;
        final duration = totalDistance / widget.velocity;

        _animationController.duration = Duration(seconds: duration.ceil());

        _animation = Tween<double>(
          begin: 0.0,
          end: totalDistance,
        ).animate(_animationController);

        // Add a listener that will update the scroll position
        _animation.addListener(() {
          if (_scrollController.hasClients) {
            // For RTL text direction, scroll in the opposite direction
            final scrollValue = _animation.value;
            _scrollController.jumpTo(scrollValue % _contentSize);
          }
        });

        _animationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = SingleChildScrollView(
      scrollDirection: widget.scrollAxis,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(widget.text, style: widget.style, maxLines: 1),
      ),
    );

    // Add fading effect on the edges if showFading is true
    if (widget.showFading) {
      return ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0.0, 0.1, 0.9, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: child,
      );
    }

    return child;
  }
}
