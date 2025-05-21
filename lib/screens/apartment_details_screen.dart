import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/apartment.dart';
import '../services/booking_service_supabase.dart';

class ApartmentDetailsScreen extends StatefulWidget {
  final Apartment apartment;

  const ApartmentDetailsScreen({super.key, required this.apartment});

  @override
  State<ApartmentDetailsScreen> createState() => _ApartmentDetailsScreenState();
}

// تغيير اسم الصفحة إلى PropertyDetailsScreen
class PropertyDetailsScreen extends StatefulWidget {
  final Apartment property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() {
    return _PropertyDetailsScreenState();
  }
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final Logger _logger = Logger('PropertyDetailsScreen');

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام widget.property بدلاً من widget.apartment
    final apartment = widget.property;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(apartment.name), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // استخدام نفس الدوال من _ApartmentDetailsScreenState
            // ولكن مع تمرير apartment بدلاً من widget.apartment
            _buildImageCarousel(apartment),

            // معلومات العقار
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم العقار
                  Text(
                    apartment.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // الموقع
                  Row(
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apartment.location,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // السعر
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${apartment.price.toStringAsFixed(0)} جنيه',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // الوصف
                  Text(
                    'الوصف',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(apartment.description),

                  const SizedBox(height: 24),

                  // المميزات
                  if (apartment.features.isNotEmpty) ...[
                    Text(
                      'المميزات',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          apartment.features.map((feature) {
                            return Chip(
                              label: Text(feature),
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(25),
                            );
                          }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // زر الحجز
                  ElevatedButton.icon(
                    onPressed: () {
                      // فتح صفحة الحجز
                      _logger.info(
                        'تم النقر على زر الحجز للعقار: ${apartment.id}',
                      );

                      // استخدام خدمة الحجز
                      final bookingService = BookingServiceSupabase();

                      // عرض رسالة للمستخدم
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('جاري تجهيز صفحة الحجز...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.book_online),
                    label: const Text('طلب حجز'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نسخ الدوال الأساسية المطلوبة
  Widget _buildImageCarousel(Apartment apartment) {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enableInfiniteScroll: apartment.imageUrls.length > 1,
            autoPlay: apartment.imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items:
              apartment.imageUrls.isEmpty
                  ? [
                    Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  ]
                  : apartment.imageUrls.map((url) {
                    return Builder(
                      builder: (BuildContext context) {
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder:
                              (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            _logger.warning('خطأ في تحميل الصورة: $error');
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.error, size: 40),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
        ),

        // Images indicator
        if (apartment.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  apartment.imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(
                          _currentImageIndex == entry.key ? 230 : 102,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ApartmentDetailsScreenState extends State<ApartmentDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isBookingFormVisible = false;
  final Logger _logger = Logger('ApartmentDetailsScreen');

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _launchCall() async {
    // هنا يمكن وضع رقم الهاتف الفعلي للاتصال
    const String phoneNumber = 'tel:+201234567890';
    final Uri uri = Uri.parse(phoneNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن الاتصال حالياً، يرجى المحاولة لاحقاً'),
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsapp() async {
    // هنا يمكن وضع رقم الواتساب الفعلي
    const String phoneNumber = '+201234567890';
    final Uri uri = Uri.parse(
      'https://wa.me/$phoneNumber?text=استفسار عن شقة: ${widget.apartment.name}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح واتساب حالياً، يرجى المحاولة لاحقاً'),
          ),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // إذا كان تاريخ البداية بعد تاريخ النهاية، نقوم بتعديل تاريخ النهاية
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate ??
          (_startDate?.add(const Duration(days: 1)) ??
              DateTime.now().add(const Duration(days: 1))),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleBookingForm() {
    setState(() {
      _isBookingFormVisible = !_isBookingFormVisible;
    });
  }

  Future<void> _submitBookingRequest() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ إرسال طلب الحجز...'),
                ],
              ),
            ),
      );

      // الحصول على معرّف المستخدم الحالي (إذا كان متاحًا)
      String? userId;
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          userId = user.id;
        }
      } catch (e) {
        if (!mounted) return;
        _logger.warning(
          'المستخدم غير مسجل دخول أو خطأ في الحصول على معرف المستخدم: $e',
        );
      }

      // إنشاء كائن طلب الحجز
      final bookingRequest = {
        'property_id': widget.apartment.id,
        'property_name': widget.apartment.name,
        'property_location': widget.apartment.location,
        'property_price': widget.apartment.price,
        'customer_name': _nameController.text,
        'customer_phone': _phoneController.text,
        'notes': _notesController.text,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'status': 'pending', // حالة الطلب: قيد الانتظار
        'created_at': DateTime.now().toIso8601String(),
        'user_id': userId, // معرّف المستخدم (إذا كان متاحًا)
      };

      // استخدام خدمة الحجز لإرسال الطلب
      final bookingService = BookingServiceSupabase();
      await bookingService.addBookingRequest(bookingRequest);

      if (!mounted) return;

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب الحجز بنجاح، سيتم التواصل معك قريباً'),
          backgroundColor: Colors.green,
        ),
      );

      // إعادة تعيين النموذج
      setState(() {
        _isBookingFormVisible = false;
        _nameController.clear();
        _phoneController.clear();
        _notesController.clear();
        _startDate = null;
        _endDate = null;
      });
    } catch (e) {
      if (!mounted) return;

      // إغلاق مؤشر التحميل إذا كان مفتوحًا
      Navigator.of(context, rootNavigator: true).pop();

      // عرض رسالة خطأ
      _logger.severe('خطأ في إرسال طلب الحجز: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال طلب الحجز: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final apartment = widget.apartment;

    return Scaffold(
      appBar: AppBar(title: Text(widget.apartment.name), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Carousel
            _buildImageCarousel(apartment),

            // Rest of the content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and action buttons
                  _buildPriceAndActionButtons(apartment, theme, isDarkMode),

                  const SizedBox(height: 24),

                  // Overview Section
                  _buildSectionTitle('نظرة عامة', Icons.info_outline),
                  const SizedBox(height: 12),
                  _buildOverviewSection(apartment, theme, isDarkMode),

                  const SizedBox(height: 24),

                  // Description Section
                  _buildSectionTitle('وصف الشقة', Icons.description_outlined),
                  const SizedBox(height: 12),
                  Text(
                    apartment.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 24),

                  // Features Section
                  if (apartment.features.isNotEmpty) ...[
                    _buildSectionTitle('المميزات', Icons.hotel_class_outlined),
                    const SizedBox(height: 12),
                    _buildAmenitiesGrid(apartment.features, theme),
                    const SizedBox(height: 24),
                  ],

                  // Videos Section
                  if (apartment.videos.isNotEmpty) ...[
                    _buildSectionTitle(
                      'فيديوهات',
                      Icons.video_library_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildVideosList(apartment.videos, theme, isDarkMode),
                    const SizedBox(height: 24),
                  ],

                  // Booking Form Section
                  _buildBookingSection(theme),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(Apartment apartment) {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enableInfiniteScroll: apartment.imageUrls.length > 1,
            autoPlay: apartment.imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items:
              apartment.imageUrls.isEmpty
                  ? [
                    Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  ]
                  : apartment.imageUrls.map((url) {
                    return Builder(
                      builder: (BuildContext context) {
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder:
                              (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            _logger.warning('خطأ في تحميل الصورة: $error');
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.error, size: 40),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
        ),

        // Images indicator
        if (apartment.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  apartment.imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(
                          _currentImageIndex == entry.key ? 230 : 102,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceAndActionButtons(
    Apartment apartment,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          apartment.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Location
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: isDarkMode ? Colors.lightBlue : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                apartment.location,
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_money, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${apartment.price.toStringAsFixed(0)} جنيه',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _launchCall,
                icon: const Icon(Icons.call),
                label: const Text('اتصل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _launchWhatsapp,
                icon: const Icon(Icons.message),
                label: const Text('واتساب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(
    Apartment apartment,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        _buildOverviewItem(
          icon: Icons.meeting_room_outlined,
          value: apartment.rooms.toString(),
          label: 'غرف',
          theme: theme,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 24),
        _buildOverviewItem(
          icon: Icons.apartment_outlined,
          value: 'متاح',
          label: 'الحالة',
          theme: theme,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 24),
        _buildOverviewItem(
          icon: Icons.calendar_today_outlined,
          value: _formatDate(apartment.createdAt),
          label: 'تاريخ النشر',
          theme: theme,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesGrid(List<String> amenities, ThemeData theme) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          amenities.map((amenity) {
            return Chip(
              label: Text(amenity),
              backgroundColor: theme.colorScheme.primary.withAlpha(25),
              labelStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              avatar: Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildVideosList(
    List<String> videos,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Column(
      children:
          videos.map((url) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.video_library, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'فيديو الشقة',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final Uri uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('لا يمكن فتح الفيديو'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('مشاهدة'),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBookingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleBookingForm,
          icon: Icon(_isBookingFormVisible ? Icons.close : Icons.book_online),
          label: Text(_isBookingFormVisible ? 'إلغاء طلب الحجز' : 'طلب حجز'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isBookingFormVisible ? Colors.red : theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        if (_isBookingFormVisible) ...[
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'طلب حجز',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الاسم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Range
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ البداية',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _startDate == null
                                    ? 'اختر التاريخ'
                                    : _formatDate(_startDate!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ النهاية',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _endDate == null
                                    ? 'اختر التاريخ'
                                    : _formatDate(_endDate!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitBookingRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('إرسال طلب الحجز'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
