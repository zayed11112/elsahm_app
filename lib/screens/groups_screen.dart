import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Theme colors
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color secondaryBlue = const Color(0xFF42A5F5);
  final Color facebookColor = const Color(0xFF1877F2);
  final Color whatsappColor = const Color(0xFF25D366);
  final Color telegramColor = const Color(0xFF0088CC);

  @override
  void initState() {
    super.initState();
    // Reordering tabs to prioritize WhatsApp
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Launch URL function
  Future<void> _launchUrl(String url) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'لا يمكن فتح الرابط',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.fixed,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء فتح الرابط',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Copy URL function
  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url)).then((_) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم نسخ الرابط',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardBackgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'جروبات السهم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              text: 'واتساب',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: whatsappColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat, size: 20, color: Colors.white),
              ),
            ),
            Tab(
              text: 'فيسبوك',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: facebookColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.facebook,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Tab(
              text: 'تليجرام',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: telegramColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.telegram,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // Reordering tab content to match new tab order
              _buildWhatsAppGroups(
                cardBackgroundColor,
                textColor,
                subtitleColor,
              ),
              _buildFacebookGroups(
                cardBackgroundColor,
                textColor,
                subtitleColor,
              ),
              _buildTelegramGroups(
                cardBackgroundColor,
                textColor,
                subtitleColor,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppGroups(
    Color cardBackground,
    Color textColor,
    Color subtitleColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics section at the top
          _buildStatisticsSection(cardBackground, textColor, subtitleColor),
          const SizedBox(height: 24),

          // College groups section - prioritized at the top
          _buildSectionTitle(
            'جروبات الكليات والمساعدة',
            Icons.school,
            primaryBlue,
            textColor,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCollageGroupCard(
                title: 'كلية حاسبات ومعلومات',
                url: 'https://chat.whatsapp.com/FmtwyGpKeEb4lbi1BIsa2N',
                color: whatsappColor,
                icon: Icons.computer,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildCollageGroupCard(
                title: 'كلية هندسة',
                url: 'https://chat.whatsapp.com/LGTT9PkgbioBJZduXgsm1X',
                color: whatsappColor,
                icon: Icons.architecture,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildCollageGroupCard(
                title: 'كلية صيدلة',
                url: 'https://chat.whatsapp.com/KGCriMsNwmw2BEpIdRqvqa',
                color: whatsappColor,
                icon: Icons.local_pharmacy,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildCollageGroupCard(
                title: 'كلية اسنان',
                url: 'https://chat.whatsapp.com/CgRMonMcvCA4l6JcyhyR9N',
                color: whatsappColor,
                icon: Icons.medical_services,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildCollageGroupCard(
                title: 'للاستفسار والتقديم',
                url: 'https://chat.whatsapp.com/EDAq5ZbnZlL6F4Fhwwt8q6',
                color: whatsappColor,
                icon: Icons.help_outline,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // General housing group section
          _buildSectionTitle(
            '  جروبات السكن فرع العريش',
            Icons.home,
            whatsappColor,
            textColor,
          ),
          const SizedBox(height: 16),

          _buildGroupCard(
            title: 'جروب السهم للتسكين 1',
            description: 'جروب عام للتسكين الطلابي',
            url: 'https://chat.whatsapp.com/HLW95JRHLwpH1sBaVhW0A6',
            iconData: Icons.apartment,
            color: whatsappColor,
            cardBackground: cardBackground,
            textColor: textColor,
            subtitleColor: subtitleColor,
            joinText: 'انضمام للجروب',
          ),
          const SizedBox(height: 12),

          _buildGroupCard(
            title: 'جروب السهم للتسكين 2',
            description: 'جروب إضافي للتسكين الطلابي',
            url: 'https://chat.whatsapp.com/JMYVMCTwTxACjKwgNOPDso',
            iconData: Icons.apartment,
            color: whatsappColor,
            cardBackground: cardBackground,
            textColor: textColor,
            subtitleColor: subtitleColor,
            joinText: 'انضمام للجروب',
          ),
        ],
      ),
    );
  }

  Widget _buildFacebookGroups(
    Color cardBackground,
    Color textColor,
    Color subtitleColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics section for Facebook
          _buildFacebookStatisticsSection(
            cardBackground,
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 24),

          // Section title
          _buildSectionTitle(
            'صفحات وجروبات فيسبوك',
            Icons.facebook,
            facebookColor,
            textColor,
          ),
          const SizedBox(height: 16),

          // Facebook groups with modern design
          _buildModernFacebookCard(
            title: 'جروب السهم - فيسبوك',
            description: '+5000 عضو',
            url: 'https://www.facebook.com/groups/590597414668538',
            cardBackground: cardBackground,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 16),

          _buildModernFacebookCard(
            title: 'صفحة شركة السهم العريش',
            description: '+10000 متابع',
            url: 'https://www.facebook.com/elsahm.arish',
            cardBackground: cardBackground,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramGroups(
    Color cardBackground,
    Color textColor,
    Color subtitleColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics section for Telegram
          _buildTelegramStatisticsSection(
            cardBackground,
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 24),

          // Section title
          _buildSectionTitle(
            'جروبات تليجرام شركة السهم',
            Icons.telegram,
            telegramColor,
            textColor,
          ),
          const SizedBox(height: 16),

          // Housing categories with modern design
          _buildModernSectionHeader('أنواع السكن', textColor),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildModernTelegramCard(
                title: 'سكن استديو',
                subtitle: 'ولاد و بنات',
                url: 'https://t.me/elsahmStudio',
                icon: Icons.hotel,
              ),
              _buildModernTelegramCard(
                title: 'سكن بالاوضة أو سرير',
                subtitle: 'أولاد',
                url: 'https://t.me/elsahmboys',
                icon: Icons.single_bed,
              ),
              _buildModernTelegramCard(
                title: 'سكن بالاوضة أو سرير',
                subtitle: 'بنات',
                url: 'https://t.me/elsahmgirls',
                icon: Icons.single_bed,
              ),
              _buildModernTelegramCard(
                title: 'قرية سما العريش',
                subtitle: 'سكن طلابي',
                url: 'https://t.me/elsahmsama',
                icon: Icons.location_city,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildModernSectionHeader('شقق سكنية', textColor),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            childAspectRatio: 0.85,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCompactTelegramCard(
                title: 'شقق',
                subtitle: '2 غرفة',
                url: 'https://t.me/elsahmtwo',
                icon: Icons.apartment,
              ),
              _buildCompactTelegramCard(
                title: 'شقق',
                subtitle: '3 غرف',
                url: 'https://t.me/elsahmthree',
                icon: Icons.apartment,
              ),
              _buildCompactTelegramCard(
                title: 'شقق',
                subtitle: '4 غرف',
                url: 'https://t.me/elsahmfour',
                icon: Icons.apartment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Statistics section widget
  Widget _buildStatisticsSection(
    Color cardBackground,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFE8F5E8), const Color(0xFFF0F8FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.school,
              count: '5',
              label: 'جروبات كليات',
              color: const Color(0xFF4CAF50),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.home,
              count: '2',
              label: 'جروبات سكن',
              color: const Color(0xFF2196F3),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              count: '7',
              label: 'إجمالي',
              color: const Color(0xFF9C27B0),
              textColor: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Facebook statistics section widget
  Widget _buildFacebookStatisticsSection(
    Color cardBackground,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.group,
              count: '1',
              label: 'جروب',
              color: const Color(0xFF1976D2),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pages,
              count: '1',
              label: 'صفحة',
              color: const Color(0xFF1976D2),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              count: '15K+',
              label: 'متابع',
              color: const Color(0xFF1976D2),
              textColor: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Facebook card widget
  Widget _buildModernFacebookCard({
    required String title,
    required String description,
    required String url,
    required Color cardBackground,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // App icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/logo_elsham.webp',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.facebook,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'فتح الرابط',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'نسخ',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
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
      ),
    );
  }

  // Individual stat card widget
  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Telegram statistics section widget
  Widget _buildTelegramStatisticsSection(
    Color cardBackground,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFE1F5FE), const Color(0xFFF3E5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.hotel,
              count: '4',
              label: 'أنواع سكن',
              color: const Color(0xFF0288D1),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.apartment,
              count: '3',
              label: 'شقق سكنية',
              color: const Color(0xFF0288D1),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              count: '7',
              label: 'إجمالي',
              color: const Color(0xFF0288D1),
              textColor: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Modern section header widget
  Widget _buildModernSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  // Modern Telegram card widget
  Widget _buildModernTelegramCard({
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container with gradient background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0288D1).withValues(alpha: 0.2),
                        const Color(0xFF29B6F6).withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFF0288D1), size: 32),
                  ),
                ),
                const SizedBox(height: 16),

                // Title text
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Subtitle text
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Join button with modern design
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF0288D1), Color(0xFF29B6F6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'انضمام',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact Telegram card widget for apartments
  Widget _buildCompactTelegramCard({
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFF0288D1), size: 24),
                  ),
                ),
                const SizedBox(height: 12),

                // Title text
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle text
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),

                // Join button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'انضمام',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern section title widget matching the reference image
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // College group card with modern design matching the reference image
  Widget _buildCollageGroupCard({
    required String title,
    required String url,
    required Color color,
    required IconData icon,
    required Color cardBackground,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container with gradient background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        const Color(0xFF81C784).withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFF4CAF50), size: 32),
                  ),
                ),
                const SizedBox(height: 16),

                // Title text
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Join button with modern design
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'انضمام',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Standard group card with image or icon for WhatsApp and Facebook
  Widget _buildGroupCard({
    required String title,
    required String description,
    required String url,
    String? imagePath,
    IconData? iconData,
    required Color color,
    required Color cardBackground,
    required Color textColor,
    required Color subtitleColor,
    required String joinText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon or image
                if (imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (iconData != null)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(iconData, color: color, size: 30),
                    ),
                  ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                      const SizedBox(height: 8),

                      // Action buttons
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  joinText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Copy button
                          GestureDetector(
                            onTap: () => _copyUrl(url),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, size: 14, color: textColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'نسخ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
