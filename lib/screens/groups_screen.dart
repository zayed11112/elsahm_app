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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('لا يمكن فتح الرابط'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ الرابط'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardBackgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'جروبات السهم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryBlue,
          indicatorWeight: 3,
          labelColor: isDarkMode ? Colors.white : primaryBlue,
          unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          tabs: [
            // Reordering tabs to prioritize WhatsApp
            Tab(
              text: 'واتساب',
              icon: Image.asset('assets/icons/whatsapp_icon.png', width: 24, height: 24),
            ),
            Tab(
              text: 'فيسبوك',
              icon: Icon(Icons.facebook, color: facebookColor),
            ),
            Tab(
              text: 'تليجرام',
              icon: Icon(Icons.telegram, color: telegramColor),
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
              _buildWhatsAppGroups(cardBackgroundColor, textColor, subtitleColor),
              _buildFacebookGroups(cardBackgroundColor, textColor, subtitleColor),
              _buildTelegramGroups(cardBackgroundColor, textColor, subtitleColor),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppGroups(Color cardBackground, Color textColor, Color subtitleColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildFacebookGroups(Color cardBackground, Color textColor, Color subtitleColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle(
            'صفحات وجروبات فيسبوك',
            Icons.facebook,
            facebookColor,
            textColor,
          ),
          const SizedBox(height: 16),
          _buildGroupCard(
            title: 'جروب السهم - فيسبوك',
            description: '+5000 عضو',
            url: 'https://www.facebook.com/groups/590597414668538',
            imagePath: 'assets/images/app_icon.png',
            color: facebookColor,
            cardBackground: cardBackground,
            textColor: textColor,
            subtitleColor: subtitleColor,
            joinText: 'فتح الرابط',
          ),
          const SizedBox(height: 12),
          _buildGroupCard(
            title: 'صفحة شركة السهم العريش',
            description: '+10000 متابع',
            url: 'https://www.facebook.com/elsahm.arish',
            imagePath: 'assets/images/app_icon.png',
            color: facebookColor,
            cardBackground: cardBackground,
            textColor: textColor,
            subtitleColor: subtitleColor,
            joinText: 'فتح الرابط',
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramGroups(Color cardBackground, Color textColor, Color subtitleColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'جروبات تليجرام شركة السهم',
            Icons.telegram,
            telegramColor,
            textColor,
          ),
          const SizedBox(height: 16),
          
          // Housing categories
          Text(
            'أنواع السكن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTelegramGroupTile(
                title: 'سكن استديو',
                subtitle: 'ولاد و بنات',
                url: 'https://t.me/elsahmStudio',
                color: telegramColor,
                icon: Icons.hotel,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildTelegramGroupTile(
                title: 'سكن بالاوضة او سرير',
                subtitle: 'اولاد',
                url: 'https://t.me/elsahmboys',
                color: telegramColor,
                icon: Icons.single_bed,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildTelegramGroupTile(
                title: 'سكن بالاوضة او سرير',
                subtitle: 'بنات',
                url: 'https://t.me/elsahmgirls',
                color: telegramColor,
                icon: Icons.single_bed,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
              _buildTelegramGroupTile(
                title: 'قرية سما العريش',
                subtitle: 'سكن طلابي',
                url: 'https://t.me/elsahmsama',
                color: telegramColor,
                icon: Icons.location_city,
                cardBackground: cardBackground,
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 24),
          
          Text(
            'شقق سكنية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            childAspectRatio: 0.9,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTelegramGroupTile(
                title: 'شقق',
                subtitle: '2 غرفة',
                url: 'https://t.me/elsahmtwo',
                color: telegramColor,
                icon: Icons.apartment,
                cardBackground: cardBackground,
                textColor: textColor,
                compact: true,
              ),
              _buildTelegramGroupTile(
                title: 'شقق',
                subtitle: '3 غرف',
                url: 'https://t.me/elsahmthree',
                color: telegramColor,
                icon: Icons.apartment,
                cardBackground: cardBackground,
                textColor: textColor,
                compact: true,
              ),
              _buildTelegramGroupTile(
                title: 'شقق',
                subtitle: '4 غرف',
                url: 'https://t.me/elsahmfour',
                color: telegramColor,
                icon: Icons.apartment,
                cardBackground: cardBackground,
                textColor: textColor,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shared section title widget with improved design
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // College group card with compact design
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
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'انضمام',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
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
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: textColor,
                                  ),
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

  // Telegram group tile with compact design
  Widget _buildTelegramGroupTile({
    required String title,
    required String subtitle,
    required String url,
    required Color color,
    required IconData icon,
    required Color cardBackground,
    required Color textColor,
    bool compact = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
            padding: compact 
                ? const EdgeInsets.all(10)
                : const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 40 : 50,
                  height: compact ? 40 : 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: compact ? 22 : 28),
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Container(
                  padding: compact
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
                      : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.telegram,
                        color: Colors.white,
                        size: compact ? 12 : 14,
                      ),
                      SizedBox(width: compact ? 3 : 4),
                      Text(
                        'انضمام',
                        style: TextStyle(
                          fontSize: compact ? 10 : 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
