import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // Company information
  static const String companyName = 'شركة السهم';
  static const String companyEmail = 'elsahm.arish@gmail.com';
  static const String companyPhoneNumber = '01093130120';
  static const String companyWhatsappNumber = '+201093130120';
  static const String companyFacebookUrl = 'https://www.facebook.com/elsahm.arish';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976d3),
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
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1976d3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نوفر أفضل خيارات السكن للطلاب والعائلات في العريش',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'فريقنا جاهز لمساعدتك',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Contact methods title
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 24, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'وسائل التواصل',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            
            // Contact cards
            _buildContactCard(
              context: context,
              title: 'اتصل بنا',
              subtitle: companyPhoneNumber,
              icon: Icons.phone,
              iconColor: Colors.green,
              onTap: () => _launchCall(companyPhoneNumber),
            ),
            
            _buildContactCard(
              context: context,
              title: 'واتساب',
              subtitle: companyWhatsappNumber,
              icon: Icons.chat,
              iconColor: Colors.green.shade600,
              onTap: () => _launchWhatsApp(companyWhatsappNumber),
            ),
            
            _buildContactCard(
              context: context,
              title: 'البريد الإلكتروني',
              subtitle: companyEmail,
              icon: Icons.email,
              iconColor: Colors.red,
              onTap: () => _launchEmail(companyEmail),
            ),
            
            _buildContactCard(
              context: context,
              title: 'فيسبوك',
              subtitle: 'تابعنا على فيسبوك',
              icon: Icons.facebook,
              iconColor: const Color(0xFF1877F2),
              onTap: () => _launchURL(companyFacebookUrl),
            ),
            
          
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
