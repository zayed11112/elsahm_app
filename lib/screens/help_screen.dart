import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart'; // إضافة مكتبة لفتح الاتصال الهاتفي
import 'package:logging/logging.dart';
import '../constants/theme.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static final Logger _logger = Logger('HelpScreen');

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : lightBackground,
      appBar: AppBar(
        backgroundColor: appBarBlue,
        title: const Text(
          'المساعدة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // قائمة الأسئلة الشائعة - قابلة للتمرير بشكل مستقل مع العنوان
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black12 : Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // رسم متحرك في الأعلى للترحيب - متحرك مع المحتوى
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 5, bottom: 5),
                      child: Lottie.asset(
                        'assets/animations/support.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.support_agent,
                              size: 70,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),

                    // عنوان صفحة المساعدة - متحرك مع المحتوى
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 24,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'كيف يمكننا مساعدتك؟',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // جملة ترحيبية - متحرك مع المحتوى
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 15,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'هنا ستجد إجابات على الأسئلة الشائعة، ويمكنك التواصل معنا في حال احتجت مساعدة إضافية',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // أسئلة شائعة
                    _buildFAQItem(
                      context,
                      question: 'كيف يمكنني حجز سكن طلابي؟',
                      answer:
                          'يمكنك الحجز من خلال الضغط على السكن المناسب لك من الصفحة الرئيسية، ثم اختيار الغرفة المناسبة والضغط على زر "حجز". ستحتاج لتسجيل الدخول أو إنشاء حساب جديد إذا لم يكن لديك حساب مسبقاً.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'ما هي طرق الدفع المتاحة؟',
                      answer:
                          'يمكنك الدفع من خلال: فودافون كاش وإنستا باي فقط. جميع المعاملات المالية مؤمنة وتستخدم تشفير SSL بنسبة 128 بت.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'كيف يمكنني شحن رصيدي؟',
                      answer:
                          'يمكنك شحن رصيدك من خلال زيارة صفحة "المحفظة" أو من خلال الضغط على أيقونة الرصيد في أعلى التطبيق. ثم اختيار طريقة الدفع المناسبة وإتباع التعليمات لإتمام عملية الشحن.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'هل يمكنني الحجز لصديقي؟',
                      answer:
                          'نعم، يمكنك الحجز لصديق من خلال إضافة بياناته أثناء عملية الحجز، ولكن يجب أن يكون لديك رصيد كافي لإتمام الحجز. يمكنك حجز ما يصل إلى 5 أشخاص في عملية حجز واحدة.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'ما هي سياسة الإلغاء والاسترداد؟',
                      answer:
                          'سياسة الإلغاء والاسترداد تختلف حسب وقت الإلغاء:\n• إلغاء قبل 30 يوم من تاريخ الإقامة: استرداد 100% من المبلغ\n• إلغاء قبل 15 يوم: استرداد 75% من المبلغ\n• إلغاء قبل 7 أيام: استرداد 50% من المبلغ\n• إلغاء خلال أقل من 7 أيام: لا يوجد استرداد\nفي حالات طارئة معينة، قد يتم النظر في استثناءات لهذه السياسة.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'كيف يمكنني إلغاء حجزي؟',
                      answer:
                          'يمكنك إلغاء الحجز من خلال الذهاب لصفحة "حجوزاتي" في قائمة حسابي، ثم الضغط على الحجز المراد إلغاؤه واختيار "إلغاء الحجز". يرجى ملاحظة أن سياسة الإلغاء تختلف حسب وقت الإلغاء وقرب موعد الإقامة.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'متى سأتمكن من استلام السكن؟',
                      answer:
                          'يمكنك استلام السكن في التاريخ المحدد للحجز بداية من الساعة 12 ظهراً. في حالة الرغبة في تسجيل الدخول المبكر، يرجى التواصل مع خدمة العملاء قبل 24 ساعة على الأقل وقد يخضع ذلك لرسوم إضافية حسب توفر الغرف.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'ما الخدمات المتوفرة في السكن الطلابي؟',
                      answer:
                          'تختلف الخدمات حسب نوع السكن المختار، لكن معظم المساكن توفر:\n• واي فاي عالي السرعة\n• خدمات أمن على مدار 24 ساعة\n• غرف مفروشة بالكامل\n• مرافق غسيل الملابس\n• مناطق مشتركة للدراسة والاسترخاء\n• خدمات تنظيف دورية\n• مواصلات للجامعة في بعض المواقع\n\nيمكنك الاطلاع على تفاصيل الخدمات المتوفرة في صفحة كل سكن على حدة.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'هل يمكنني تغيير غرفتي بعد الحجز؟',
                      answer:
                          'نعم، يمكنك طلب تغيير الغرفة بعد الحجز، ولكن هذا يخضع لتوفر الغرف وقد تنطبق رسوم تغيير إضافية. يجب تقديم طلب التغيير قبل 7 أيام على الأقل من تاريخ الإقامة للنظر فيه. يمكنك التقدم بطلب التغيير من خلال التواصل مع خدمة العملاء.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'كيف يمكنني التواصل مع خدمة العملاء؟',
                      answer:
                          'يمكنك التواصل معنا من خلال:\n• الاتصال المباشر على رقم 01093130120 (من 9 صباحاً حتى 9 مساءً طوال أيام الأسبوع)\n• البريد الإلكتروني: elsahm.arish@gmail.com\n• الدردشة المباشرة داخل التطبيق\n• عبر حساباتنا على وسائل التواصل الاجتماعي\n\nفريق خدمة العملاء متاح دائماً للرد على استفساراتك والمساعدة في حل أي مشكلة قد تواجهها.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'كيف يمكنني تغيير كلمة المرور؟',
                      answer:
                          'يمكنك تغيير كلمة المرور من خلال الذهاب لإعدادات الحساب، ثم اختيار "تغيير كلمة المرور". ستحتاج لإدخال كلمة المرور الحالية ثم إدخال كلمة المرور الجديدة وتأكيدها. في حالة نسيان كلمة المرور الحالية، يمكنك استخدام خيار "نسيت كلمة المرور" في شاشة تسجيل الدخول.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'ما هي متطلبات حجز السكن الطلابي؟',
                      answer:
                          'لحجز سكن طلابي ستحتاج إلى:\n• حساب على التطبيق مع بيانات شخصية مكتملة\n• صورة من البطاقة الشخصية أو جواز السفر\n• إثبات القيد في الجامعة (كارنيه الجامعة أو خطاب قبول)\n• سداد قيمة الحجز أو المقدمة المطلوبة\n\nقد تختلف المتطلبات قليلاً حسب السكن والجامعة.',
                    ),

                    _buildFAQItem(
                      context,
                      question: 'هل يمكنني استرداد أموالي بعد الحجز؟',
                      answer:
                          'نعم، يمكن استرداد الأموال وفقاً لسياسة الاسترداد والإلغاء المتبعة، ويعتمد ذلك على وقت الإلغاء وشروط الإقامة. يرجى مراجعة بند "ما هي سياسة الإلغاء والاسترداد؟" للتفاصيل الكاملة أو التواصل مع خدمة العملاء للحصول على معلومات أكثر تفصيلاً.',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // قسم الاتصال بالدعم - ثابت في الأسفل
          Container(
            width: MediaQuery.of(context).size.width * 0.95,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'لم تجد ما تبحث عنه؟',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'فريق الدعم الفني متاح للمساعدة طوال اليوم',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // أزرار التواصل
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر الاتصال الهاتفي
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('اتصل بنا'),
                        onPressed: () => _makePhoneCall('01093130120'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // زر المراسلة
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('راسلنا'),
                        onPressed: () => _sendEmail('elsahm.arish@gmail.com'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.grey[700] : Colors.grey[200],
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء عنصر السؤال والجواب بتصميم قابل للطي
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [
                    const Color(0xFF2D3748).withValues(alpha: 0.7),
                    const Color(0xFF1A202C).withValues(alpha: 0.7),
                  ]
                  : [Colors.white, const Color(0xFFF5F7FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.center,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black12 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Text(
                answer,
                style: TextStyle(
                  height: 1.5,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإجراء اتصال هاتفي
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      await launchUrl(launchUri);
    } catch (e) {
      _logger.severe('لا يمكن الاتصال: $e');
    }
  }

  // دالة لإرسال بريد إلكتروني
  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'استفسار من تطبيق السهم للتسكين'},
    );

    try {
      await launchUrl(launchUri);
    } catch (e) {
      _logger.severe('لا يمكن فتح تطبيق البريد: $e');
    }
  }
}
