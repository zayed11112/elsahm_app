import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../services/firestore_service.dart';
import 'complaint_detail_screen.dart';
import '../models/booking.dart';

class ComplaintsScreen extends StatefulWidget {
  final Booking? bookingToCancel;
  
  const ComplaintsScreen({
    super.key,
    this.bookingToCancel,
  });

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  final ComplaintService _complaintService = ComplaintService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Pre-fill complaint form if there's a booking to cancel
    if (widget.bookingToCancel != null) {
      final booking = widget.bookingToCancel!;
      _titleController.text = 'طلب إلغاء الحجز: ${booking.apartmentName}';
      _descriptionController.text = 'أرغب في إلغاء الحجز الخاص بي\n'
          'اسم الوحدة: ${booking.apartmentName}\n'
          'رقم الحجز: ${booking.id}\n'
          'تاريخ الحجز: ${booking.startDate.toString().substring(0, 10)}\n'
          'سبب الإلغاء: ';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddComplaintBottomSheet(
    BuildContext context,
    String userId,
    String userName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28.0),
                  topRight: Radius.circular(28.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with centered indicator
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تقديم شكوى جديدة',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Color.fromRGBO(
                                128,
                                128,
                                128,
                                0.1,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'عنوان الشكوى',
                          hintText: 'اكتب عنوانًا موجزًا للشكوى',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(
                                Theme.of(context).primaryColor.r.toInt(),
                                Theme.of(context).primaryColor.g.toInt(),
                                Theme.of(context).primaryColor.b.toInt(),
                                0.3,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(
                                Theme.of(context).primaryColor.r.toInt(),
                                Theme.of(context).primaryColor.g.toInt(),
                                Theme.of(context).primaryColor.b.toInt(),
                                0.3,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال عنوان للشكوى';
                          }
                          if (value.length < 5) {
                            return 'العنوان قصير جدًا، الرجاء كتابة المزيد';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'تفاصيل الشكوى',
                          hintText: 'اكتب تفاصيل المشكلة التي تواجهها',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Icon(Icons.description),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(
                                Theme.of(context).primaryColor.r.toInt(),
                                Theme.of(context).primaryColor.g.toInt(),
                                Theme.of(context).primaryColor.b.toInt(),
                                0.3,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(
                                Theme.of(context).primaryColor.r.toInt(),
                                Theme.of(context).primaryColor.g.toInt(),
                                Theme.of(context).primaryColor.b.toInt(),
                                0.3,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال تفاصيل الشكوى';
                          }
                          if (value.length < 20) {
                            return 'الوصف قصير جدًا، الرجاء كتابة المزيد من التفاصيل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        _isSubmitting = true;
                                      });

                                      // Capturar context y crear objetos necesarios antes de la operación async
                                      final scaffoldMessenger =
                                          ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(context);

                                      try {
                                        // Crear objeto de queja
                                        await _complaintService.createComplaint(
                                          userId: userId,
                                          userName: userName,
                                          title: _titleController.text.trim(),
                                          description:
                                              _descriptionController.text
                                                  .trim(),
                                        );

                                        if (mounted) {
                                          // Usar navigator que capturamos antes
                                          navigator.pop();
                                          _titleController.clear();
                                          _descriptionController.clear();

                                          // Usar scaffoldMessenger que capturamos antes
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: const [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('تم تقديم الشكوى بنجاح'),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        // Use the pre-captured scaffoldMessenger

                                        if (mounted) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'حدث خطأ: ${e.toString()}',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isSubmitting = false;
                                          });
                                        }
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Color.fromRGBO(
                              Theme.of(context).primaryColor.r.toInt(),
                              Theme.of(context).primaryColor.g.toInt(),
                              Theme.of(context).primaryColor.b.toInt(),
                              0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'تقديم الشكوى',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول لعرض الشكاوى')),
      );
    }

    return FutureBuilder(
      future: _firestoreService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text('حدث خطأ: ${snapshot.error}')),
          );
        }

        final userName = snapshot.data!.name;
        
        // Show the complaint form automatically if we have a booking to cancel
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.bookingToCancel != null) {
            _showAddComplaintBottomSheet(context, userId, userName);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'الشكاوى',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor:
                      isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(icon: Icon(Icons.fiber_new), text: 'مفتوحة'),
                    Tab(
                      icon: Icon(Icons.pending_actions),
                      text: 'قيد المعالجة',
                    ),
                    Tab(icon: Icon(Icons.check_circle), text: 'مغلقة'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildComplaintsList(userId, 'open'),
              _buildComplaintsList(userId, 'in-progress'),
              _buildComplaintsList(userId, 'closed'),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed:
                () => _showAddComplaintBottomSheet(context, userId, userName),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add),
            label: const Text(
              'شكوى جديدة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshComplaints() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        // إعادة بناء واجهة المستخدم فقط
        // لا حاجة لتحديث البيانات لأن StreamBuilder يتعامل مع ذلك تلقائيًا
      });
    }

    // يمكن إضافة منطق إضافي هنا إذا كنت تريد تحديث أي بيانات
    // غير متصلة بـ StreamBuilder
  }

  Widget _buildComplaintsList(String userId, String status) {
    return StreamBuilder<List<Complaint>>(
      stream: _complaintService.getUserComplaints(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshComplaints,
            color: Theme.of(context).primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/empty_complaints.png',
                        width: 150,
                        height: 150,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.inbox_outlined,
                              size: 100,
                              color: Colors.grey[300],
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'لا توجد شكاوى ${_getStatusText(status)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'اسحب للأسفل لتحديث الصفحة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final complaints =
            snapshot.data!
                .where((complaint) => complaint.status == status)
                .toList();

        if (complaints.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshComplaints,
            color: Theme.of(context).primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/empty_complaints.png',
                        width: 150,
                        height: 150,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.inbox_outlined,
                              size: 100,
                              color: Colors.grey[300],
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'لا توجد شكاوى ${_getStatusText(status)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'اسحب للأسفل لتحديث الصفحة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshComplaints,
          color: Theme.of(context).primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _buildComplaintCard(context, complaint);
            },
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in-progress':
        return 'قيد المعالجة';
      case 'closed':
        return 'مغلقة';
      default:
        return '';
    }
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    final Color statusColor = _getStatusColor(complaint.status);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              statusColor.r.toInt(),
              statusColor.g.toInt(),
              statusColor.b.toInt(),
              0.08,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Color.fromRGBO(
              statusColor.r.toInt(),
              statusColor.g.toInt(),
              statusColor.b.toInt(),
              0.3,
            ),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ComplaintDetailScreen(complaintId: complaint.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          statusColor.r.toInt(),
                          statusColor.g.toInt(),
                          statusColor.b.toInt(),
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color.fromRGBO(
                            statusColor.r.toInt(),
                            statusColor.g.toInt(),
                            statusColor.b.toInt(),
                            0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(complaint.status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(complaint.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDate(complaint.createdAt),
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            complaint.responses.length.toString(),
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white : Colors.grey[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  complaint.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (complaint.responses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      complaint.responses.last.isAdmin
                                          ? Colors.purple
                                          : Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    complaint.responses.last.isAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        complaint.responses.last.responderName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              complaint.responses.last.isAdmin
                                                  ? Colors.purple
                                                  : null,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (complaint.responses.last.isAdmin)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color.fromRGBO(
                                              128,
                                              0,
                                              128,
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Color.fromRGBO(
                                                128,
                                                0,
                                                128,
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'الإدارة',
                                            style: TextStyle(
                                              color: Colors.purple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(
                                      complaint.responses.last.createdAt,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Text(
                            complaint.responses.last.responseText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color:
                                  isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.fiber_new;
      case 'in-progress':
        return Icons.pending_actions;
      case 'closed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
