import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // تعريف الألوان الرئيسية
  final Color primaryColor = const Color(0xFF2C3E50);
  final Color accentColor = const Color(0xFF3498DB);
  final Color facebookColor = const Color(0xFF1877F2);
  final Color whatsappColor = const Color(0xFF25D366);
  final Color telegramColor = const Color(0xFF0088CC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // دالة لفتح الروابط
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
              content: Text('لا يمكن فتح الرابط: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          indicatorColor: accentColor,
          indicatorWeight: 3,
          labelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'فيسبوك'),
            Tab(text: 'واتساب'),
            Tab(text: 'تليجرام'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFacebookGroups(),
              _buildWhatsAppGroups(),
              _buildTelegramGroups(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildFacebookGroups() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle(
            'صفحات وجروبات فيسبوك',
            Icons.facebook,
            facebookColor,
          ),
          const SizedBox(height: 16),
          _buildFacebookGroupCard(
            title: 'جروب السهم - فيسبوك',
            url: 'https://www.facebook.com/groups/590597414668538',
            imageUrl: '', // لن يتم استخدام هذه القيمة بعد الآن
            members: '+5000 عضو',
          ),
          const SizedBox(height: 16),
          _buildFacebookGroupCard(
            title: 'صفحة شركة السهم العريش - فيسبوك',
            url: 'https://www.facebook.com/elsahm.arish',
            imageUrl: '', // لن يتم استخدام هذه القيمة بعد الآن
            members: '+10000 متابع',
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppGroups() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('جروبات واتساب', Icons.message, whatsappColor),
          const SizedBox(height: 16),
          _buildWhatsAppGroupCard(
            title: 'جروب السهم للتسكين 1',
            url: 'https://chat.whatsapp.com/HLW95JRHLwpH1sBaVhW0A6',
            description: 'جروب عام للتسكين الطلابي',
          ),
          const SizedBox(height: 12),
          _buildWhatsAppGroupCard(
            title: 'جروب السهم للتسكين 2',
            url: 'https://chat.whatsapp.com/JMYVMCTwTxACjKwgNOPDso',
            description: 'جروب إضافي للتسكين الطلابي',
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(
            'جروبات الكليات والمساعدة',
            Icons.school,
            Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildWhatsAppGroupCard(
            title: 'جروب كلية حاسبات ومعلومات',
            url: 'https://chat.whatsapp.com/FmtwyGpKeEb4lbi1BIsa2N',
            description: 'للطلاب والطالبات في كلية الحاسبات',
          ),
          const SizedBox(height: 12),
          _buildWhatsAppGroupCard(
            title: 'جروب كلية هندسة',
            url: 'https://chat.whatsapp.com/LGTT9PkgbioBJZduXgsm1X',
            description: 'للطلاب والطالبات في كلية الهندسة',
          ),
          const SizedBox(height: 12),
          _buildWhatsAppGroupCard(
            title: 'جروب كلية صيدلة',
            url: 'https://chat.whatsapp.com/KGCriMsNwmw2BEpIdRqvqa',
            description: 'للطلاب والطالبات في كلية الصيدلة',
          ),
          const SizedBox(height: 12),
          _buildWhatsAppGroupCard(
            title: 'جروب كلية انسان',
            url: 'https://chat.whatsapp.com/CgRMonMcvCA4l6JcyhyR9N',
            description: 'للطلاب والطالبات في كلية الآداب والعلوم الإنسانية',
          ),
          const SizedBox(height: 12),
          _buildWhatsAppGroupCard(
            title: 'جروب للاستفسار والتقديم في الجامعة',
            url: 'https://chat.whatsapp.com/EDAq5ZbnZlL6F4Fhwwt8q6',
            description: 'للاستفسارات العامة حول التقديم والقبول بالجامعة',
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramGroups() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle(
            'جروبات تليجرام شركة السهم',
            Icons.telegram,
            telegramColor,
          ),
          const SizedBox(height: 16),
          _buildTelegramGroupCard(
            title: 'سكن استديو ولاد و بنات',
            url: 'https://t.me/elsahmStudio',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
          const SizedBox(height: 12),
          _buildTelegramGroupCard(
            title: 'سكن بالاوضة او سرير اولاد',
            url: 'https://t.me/elsahmboys',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
          const SizedBox(height: 12),
          _buildTelegramGroupCard(
            title: 'سكن بالاوضة او سرير بنات',
            url: 'https://t.me/elsahmgirls',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
          const SizedBox(height: 12),
          _buildTelegramGroupCard(
            title: 'شقق 2 اوضه',
            url: 'https://t.me/elsahmtwo',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
          const SizedBox(height: 12),
          _buildTelegramGroupCard(
            title: 'شقق 3 اوضه',
            url: 'https://t.me/elsahmthree',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
          const SizedBox(height: 12),
          _buildTelegramGroupCard(
            title: 'شقق 4 اوضه',
            url: 'https://t.me/elsahmfour',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
          const SizedBox(height: 12),
          _buildTelegramGroupCard(
            title: 'قرية سما العريش',
            url: 'https://t.me/elsahmsama',
            emoji: '', // لن يتم استخدام هذه القيمة بعد الآن
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildFacebookGroupCard({
    required String title,
    required String url,
    required String imageUrl,
    required String members,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: facebookColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: facebookColor.withOpacity(0.2)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            members,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: facebookColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'فتح الرابط',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: url)).then((
                                _,
                              ) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ الرابط'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'نسخ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
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

  Widget _buildWhatsAppGroupCard({
    required String title,
    required String url,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: whatsappColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: whatsappColor.withOpacity(0.2)),
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: whatsappColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.message, color: whatsappColor, size: 30),
                  ),
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
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: whatsappColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'انضمام للجروب',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: url)).then((
                                _,
                              ) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ الرابط'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'نسخ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
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

  Widget _buildTelegramGroupCard({
    required String title,
    required String url,
    required String emoji,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: telegramColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: telegramColor.withOpacity(0.2)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/telegram-icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
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
                      const SizedBox(height: 4),
                      Text(
                        url.replaceAll('https://t.me/', '@'),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: telegramColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'فتح في تليجرام',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: url)).then((
                                _,
                              ) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ الرابط'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'نسخ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
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
