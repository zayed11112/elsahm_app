import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/theme.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // Company information
  static const String companyName = 'شركة السهم';
  static const String companyEmail = 'elsahm.arish@gmail.com';
  static const String companyPhoneNumber = '01093130120';
  static const String companyWhatsappNumber = '+201093130120';
  static const String companyFacebookUrl =
      'https://www.facebook.com/elsahm.arish';

  // Designer information
  static const String designerName = 'م. اسلام زايد';
  static const String designerImageUrl =
      'https://i.ibb.co/cKkXF2rF/1000165177.jpg';
  static const String designerPhoneNumber = '01003193622';
  static const String designerWhatsappNumber = '+201003193622';
  static const String designerFacebookUrl =
      'https://www.facebook.com/eslammosalah';
  static const String designerInstagramUrl =
      'https://www.instagram.com/eslamz11/';

  // Launch URL helper functions
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final String whatsappUrl = "https://wa.me/$number";
    await _launchURL(whatsappUrl);
  }

  Future<void> _launchCall(String number) async {
    final String callUrl = "tel:$number";
    await _launchURL(callUrl);
  }

  Future<void> _launchEmail(String email) async {
    final String emailUrl = "mailto:$email";
    await _launchURL(emailUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? darkBackground : lightBackground,
      appBar: AppBar(
        backgroundColor: appBarBlue,
        title: const Text(
          'تواصل معنا',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildCompanyHeader(theme, isDark),
            _buildContactMethodsSection(context, theme, isDark),
            _buildDesignerSection(context, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ]
                  : [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            companyName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'نوفر أفضل خيارات السكن للطلاب والعائلات في العريش',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'فريقنا جاهز لمساعدتك!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethodsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'وسائل التواصل',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildContactCard(
            icon: Icons.phone,
            title: 'اتصل بنا',
            subtitle: companyPhoneNumber,
            iconColor: Colors.green,
            onTap: () => _launchCall(companyPhoneNumber),
            theme: theme,
            isDark: isDark,
          ),
          _buildContactCard(
            icon: FontAwesomeIcons.whatsapp,
            title: 'واتساب',
            subtitle: companyWhatsappNumber,
            iconColor: Colors.green,
            onTap: () => _launchWhatsApp(companyWhatsappNumber),
            theme: theme,
            isDark: isDark,
          ),
          _buildContactCard(
            icon: Icons.email,
            title: 'البريد الإلكتروني',
            subtitle: companyEmail,
            iconColor: Colors.red,
            onTap: () => _launchEmail(companyEmail),
            theme: theme,
            isDark: isDark,
          ),
          _buildContactCard(
            icon: FontAwesomeIcons.facebook,
            title: 'فيسبوك',
            subtitle: 'تابعنا على فيسبوك',
            iconColor: Color(0xFF1877F2),
            onTap: () => _launchURL(companyFacebookUrl),
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Function() onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? theme.cardColor : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesignerSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? theme.colorScheme.surface : Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'تصميم وتطوير',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: CachedNetworkImage(
              imageUrl: designerImageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget:
                  (context, url, error) => Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            designerName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: FontAwesomeIcons.phone,
                color: Colors.green,
                onTap: () => _launchCall(designerPhoneNumber),
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                icon: FontAwesomeIcons.whatsapp,
                color: Colors.green.shade600,
                onTap: () => _launchWhatsApp(designerWhatsappNumber),
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                icon: FontAwesomeIcons.facebook,
                color: Color(0xFF1877F2),
                onTap: () => _launchURL(designerFacebookUrl),
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                icon: FontAwesomeIcons.instagram,
                color: Color(0xFFE1306C),
                onTap: () => _launchURL(designerInstagramUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
