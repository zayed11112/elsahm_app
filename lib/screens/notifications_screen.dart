import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../constants/theme.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  bool isLoading = true;
  List<NotificationModel> notifications = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? userId;
  bool hasUnreadNotifications = false;
  StreamSubscription? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) {
        setState(() {
          userId = authProvider.user!.uid;
        });
      } else {
        setState(() {
          userId = null;
        });
      }
    } catch (error) {
      // Silent error handling
    } finally {
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // إلغاء الاشتراك في تدفق البيانات عند إغلاق الصفحة
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (userId == null) {
        setState(() {
          notifications = [];
          hasUnreadNotifications = false;
          isLoading = false;
        });
        return;
      }

      // إلغاء الاشتراك السابق إن وجد
      _notificationsSubscription?.cancel();

      try {
        // استخدام استعلام بسيط بدون ترتيب
        final snapshot =
            await FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: userId!.trim())
                .get();

        // معالجة النتائج
        final List<NotificationModel> fetchedNotifications =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationModel(
                id: doc.id,
                title: data['title'] ?? '',
                body: data['body'] ?? '',
                type: data['type'] ?? 'general',
                timestamp:
                    (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isRead: data['isRead'] ?? false,
                targetScreen: data['targetScreen'],
                additionalData: data['additionalData'],
              );
            }).toList();

        // فرز البيانات في الذاكرة
        fetchedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
            hasUnreadNotifications = notifications.any(
              (notification) => !notification.isRead,
            );
            isLoading = false;
          });
        }

        // تعيين مؤقت لتحديث البيانات كل دقيقة
        _notificationsSubscription = Stream.periodic(
          const Duration(minutes: 1),
        ).listen((_) {
          if (mounted) {
            _loadNotifications();
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء تحميل الإشعارات'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // تعيين مؤقت لإيقاف التحميل في حالة عدم استجابة Firestore
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && isLoading) {
          setState(() {
            isLoading = false;
          });
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() {
      final index = notifications.indexWhere(
        (notification) => notification.id == notificationId,
      );
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
      }
    });

    try {
      if (userId != null) {
        await _notificationService.markNotificationAsRead(notificationId);
      }
    } catch (error) {
      // Silent error handling
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      notifications =
          notifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();
      hasUnreadNotifications = false;
    });

    try {
      if (userId != null) {
        await _notificationService.markAllNotificationsAsRead(userId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث جميع الإشعارات كمقروءة'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      // Silent error handling
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      if (userId != null) {
        await _notificationService.deleteNotification(notificationId);
      }

      setState(() {
        notifications.removeWhere((item) => item.id == notificationId);
        hasUnreadNotifications = notifications.any(
          (notification) => !notification.isRead,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف الإشعار'),
            backgroundColor: Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () {
                _loadNotifications();
              },
            ),
          ),
        );
      }
    } catch (error) {
      // Silent error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final emptyMessage = 'لا توجد إشعارات حتى الآن';

    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : lightBackground,
      appBar: AppBar(
        backgroundColor: appBarBlue,
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (hasUnreadNotifications)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: 'تعيين الكل كمقروء',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // محتوى الشاشة الرئيسي
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل الإشعارات...',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                    : notifications.isEmpty
                    ? _buildEmptyState(emptyMessage, isDarkMode)
                    : _buildNotificationsList(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDarkMode) {
    return FadeTransition(
      opacity: _animation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 80,
                color:
                    isDarkMode
                        ? Colors.lightBlueAccent
                        : Colors.lightBlueAccent[700],
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(bool isDarkMode) {
    return FadeTransition(
      opacity: _animation,
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8.0),
          itemBuilder: (context, index) {
            final notification = notifications[index];

            final Color cardColor = _getCardColor(notification, isDarkMode);
            final Color textColor = isDarkMode ? Colors.white : Colors.black87;

            return _buildNotificationCard(
              context,
              notification,
              cardColor,
              textColor,
              isDarkMode,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    Color cardColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإشعار؟'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('حذف'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }

          if (notification.targetScreen != null) {
            // التنقل إلى الشاشة المستهدفة (يمكن تنفيذها في المستقبل)
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
            border: Border.all(
              color:
                  !notification.isRead
                      ? (isDarkMode
                              ? Colors.lightBlueAccent
                              : Colors.lightBlueAccent[700])!
                          .withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (!notification.isRead)
                Container(
                  width: 4,
                  constraints: const BoxConstraints(minHeight: 10),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.lightBlueAccent
                            : Colors.lightBlueAccent[700],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(
                  right: 12.0,
                  left: 16.0,
                  top: 16.0,
                  bottom: 16.0,
                ),
                child: _getNotificationIcon(notification.type, isDarkMode),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          Text(
                            _formatTime(notification.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode
                                  ? Colors.white70
                                  : Colors.black87.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _getNotificationIcon(String type, bool isDarkMode) {
    final Color iconColor =
        isDarkMode ? Colors.lightBlueAccent : Colors.lightBlueAccent[700]!;

    switch (type) {
      case 'payment':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.payment, color: iconColor),
        );
      case 'booking':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_today, color: iconColor),
        );
      case 'wallet':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.account_balance_wallet, color: iconColor),
        );
      case 'system':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.info_outline, color: iconColor),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications, color: iconColor),
        );
    }
  }

  Color _getCardColor(NotificationModel notification, bool isDarkMode) {
    if (isDarkMode) {
      return notification.isRead
          ? const Color(0xFF2C3E50).withValues(alpha: 0.7)
          : const Color(0xFF2C3E50);
    } else {
      return notification.isRead
          ? Colors.white
          : Colors.lightBlue.withValues(alpha: 0.05);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final String? targetScreen;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.targetScreen,
    this.additionalData,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? targetScreen,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      targetScreen: targetScreen ?? this.targetScreen,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
