import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية والشروط', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'سياسة الخصوصية'),
            Tab(text: 'شروط الاستخدام'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // محتوى سياسة الخصوصية
          _buildPrivacyPolicy(context),
          
          // محتوى شروط الاستخدام
          _buildTermsOfService(context),
        ],
      ),
    );
  }
  
  // بناء صفحة سياسة الخصوصية
  Widget _buildPrivacyPolicy(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionImage(context, 'assets/images/privacy.png', Icons.security),
          
          _buildSectionTitle(context, 'سياسة الخصوصية'),
          
          _buildLastUpdated('آخر تحديث: 1 مايو 2023'),
          
          _buildParagraph(
            context,
            'تلتزم شركة السهم للتسكين الطلابي بحماية خصوصية مستخدمي التطبيق. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية المعلومات التي تقدمها عند استخدام تطبيقنا.',
          ),
          
          _buildSectionSubtitle(context, 'جمع المعلومات'),
          
          _buildParagraph(
            context,
            'نحن نجمع معلومات شخصية مثل الاسم ورقم الهاتف والبريد الإلكتروني والبيانات الأكاديمية (مثل الكلية والفرع والرقم الجامعي) وذلك لتقديم خدماتنا بشكل أفضل وتسهيل عملية الحجز والتواصل معك.',
          ),
          
          _buildSectionSubtitle(context, 'استخدام المعلومات'),
          
          _buildBulletPoints(
            context,
            [
              'تسهيل عمليات الحجز والدفع',
              'التواصل معك بخصوص حجوزاتك وطلباتك',
              'إرسال إشعارات مهمة تتعلق بالخدمة',
              'تحسين خدماتنا وتجربة المستخدم',
              'حل المشكلات وتقديم الدعم الفني',
            ],
          ),
          
          _buildSectionSubtitle(context, 'حماية المعلومات'),
          
          _buildParagraph(
            context,
            'نحن نتخذ إجراءات أمنية مناسبة لحماية معلوماتك الشخصية من الضياع أو سوء الاستخدام أو الوصول غير المصرح به أو الإفصاح أو التغيير. نستخدم تقنيات تشفير لحماية البيانات الحساسة.',
          ),
          
          _buildSectionSubtitle(context, 'مشاركة المعلومات'),
          
          _buildParagraph(
            context,
            'لا نشارك معلوماتك الشخصية مع أطراف ثالثة باستثناء ما هو ضروري لتقديم خدماتنا، مثل شركات الدفع ومقدمي خدمات الإسكان المتعاقدين معنا. في هذه الحالات، نتأكد من التزام هذه الأطراف بسياسات الخصوصية المناسبة.',
          ),
          
          _buildSectionSubtitle(context, 'ملفات تعريف الارتباط'),
          
          _buildParagraph(
            context,
            'نستخدم ملفات تعريف الارتباط وتقنيات مماثلة لتحسين تجربة المستخدم وجمع بيانات إحصائية عن استخدام التطبيق. يمكنك تعطيل هذه الميزات من إعدادات الجهاز أو التطبيق.',
          ),
          
          _buildSectionSubtitle(context, 'تغييرات على سياسة الخصوصية'),
          
          _buildParagraph(
            context,
            'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سيتم إخطارك بأي تغييرات جوهرية وسنوفر الإصدار المحدث على التطبيق.',
          ),
          
          _buildSectionSubtitle(context, 'اتصل بنا'),
          
          _buildParagraph(
            context,
            'إذا كانت لديك أي أسئلة حول سياسة الخصوصية، يرجى التواصل معنا عبر البريد الإلكتروني: elsahm.arish@gmail.com أو الاتصال على الرقم: 01093130120',
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // بناء صفحة شروط الاستخدام
  Widget _buildTermsOfService(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionImage(context, 'assets/images/terms.png', Icons.gavel),
          
          _buildSectionTitle(context, 'شروط الاستخدام'),
          
          _buildLastUpdated('آخر تحديث: 1 مايو 2023'),
          
          _buildParagraph(
            context,
            'برجاء قراءة شروط الاستخدام بعناية قبل استخدام التطبيق. باستخدامك للتطبيق، فإنك توافق على الالتزام بهذه الشروط.',
          ),
          
          _buildSectionSubtitle(context, 'استخدام التطبيق'),
          
          _buildParagraph(
            context,
            'يجب استخدام التطبيق فقط للأغراض المشروعة ووفقًا لهذه الشروط. يمنع منعًا باتًا استخدام التطبيق بطريقة قد تلحق الضرر بالتطبيق أو توفره أو إمكانية الوصول إليه.',
          ),
          
          _buildSectionSubtitle(context, 'إنشاء الحساب والأمان'),
          
          _buildParagraph(
            context,
            'أنت مسؤول عن الحفاظ على سرية بيانات اعتماد حسابك وكلمة المرور، وعن جميع الأنشطة التي تتم تحت حسابك. يجب إخطارنا فورًا بأي استخدام غير مصرح به لحسابك.',
          ),
          
          _buildSectionSubtitle(context, 'الحجوزات والمدفوعات'),
          
          _buildBulletPoints(
            context,
            [
              'جميع الحجوزات تخضع لتوفر الغرف والشقق',
              'يجب دفع المبلغ كاملًا أو المقدم المطلوب لتأكيد الحجز',
              'رسوم الإلغاء تعتمد على وقت الإلغاء ووفقًا لسياسة الإلغاء المعلنة',
              'يحق للشركة إلغاء أي حجز في حالة تقديم معلومات غير صحيحة',
              'المواعيد النهائية للدفع يجب الالتزام بها لتجنب إلغاء الحجز',
            ],
          ),
          
          _buildSectionSubtitle(context, 'قواعد السكن'),
          
          _buildParagraph(
            context,
            'يجب على جميع المستأجرين الالتزام بقواعد السكن التي سيتم توفيرها عند تأكيد الحجز. أي انتهاك لهذه القواعد قد يؤدي إلى إنهاء عقد الإيجار دون استرداد الرسوم.',
          ),
          
          _buildSectionSubtitle(context, 'المحتوى والملكية الفكرية'),
          
          _buildParagraph(
            context,
            'جميع حقوق الملكية الفكرية في التطبيق والمحتوى المقدم (بما في ذلك النصوص والصور والشعارات) مملوكة لشركة السهم للتسكين الطلابي. لا يجوز نسخ أو إعادة إنتاج أو توزيع أي جزء من التطبيق دون إذن كتابي مسبق.',
          ),
          
          _buildSectionSubtitle(context, 'إخلاء المسؤولية'),
          
          _buildParagraph(
            context,
            'يتم توفير الخدمة "كما هي" و"كما هي متاحة" دون أي ضمانات. لا نضمن أن التطبيق سيكون متاحًا بشكل دائم أو خالٍ من الأخطاء.',
          ),
          
          _buildSectionSubtitle(context, 'حدود المسؤولية'),
          
          _buildParagraph(
            context,
            'لن تكون شركة السهم للتسكين الطلابي مسؤولة عن أي أضرار غير مباشرة أو عرضية أو خاصة أو تبعية أو عقابية ناتجة عن استخدام التطبيق.',
          ),
          
          _buildSectionSubtitle(context, 'التعديلات على الشروط'),
          
          _buildParagraph(
            context,
            'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بالتغييرات الجوهرية، واستمرارك في استخدام التطبيق بعد نشر التغييرات يشكل موافقتك على الشروط المعدلة.',
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // بناء عنوان رئيسي للقسم
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  // بناء عنوان فرعي للقسم
  Widget _buildSectionSubtitle(BuildContext context, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
              ],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  // بناء فقرة نصية
  Widget _buildParagraph(BuildContext context, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black12
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  // بناء نقاط قائمة
  Widget _buildBulletPoints(BuildContext context, List<String> points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black12
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: points.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•  ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  // بناء تاريخ التحديث
  Widget _buildLastUpdated(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        date,
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  // بناء صورة القسم
  Widget _buildSectionImage(BuildContext context, String imagePath, IconData fallbackIcon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Center(
        child: Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Center(
            child: imagePath.isEmpty
                ? Icon(
                    fallbackIcon,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Image.asset(
                    imagePath,
                    height: 60,
                    width: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        fallbackIcon,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
} 