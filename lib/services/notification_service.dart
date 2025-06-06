import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'dart:math' show min;

// Top-level logger for background message handler
final Logger _backgroundLogger = Logger('BackgroundMessageHandler');

// Define a top-level handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _backgroundLogger.info('Handling background message: ${message.messageId}');
}

class NotificationService {
  final Logger _logger = Logger('NotificationService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'notifications';
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Initialize Notification Services
  Future<void> initialize() async {
    // لا نطلب الأذونات تلقائياً - سيتم طلبها عند الحاجة من خلال واجهة المستخدم
    // await _requestPermission(); // تم تعطيل الطلب التلقائي للأذونات

    // Configure Firebase messaging handlers (legacy)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configure foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle received messages when app is in foreground (legacy)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle notification taps (legacy)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation when app is opened from notification
      _handleNotificationTap(message);
    });

    _logger.info('Firebase Messaging initialized for legacy support');
  }

  // تم إزالة دالة _requestPermission لأنها لم تعد مستخدمة
  // الأذونات ستُطلب يدوياً من خلال واجهة المستخدم عند الحاجة

  // Handle foreground message (legacy)
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.info('Got a foreground message: ${message.messageId}');

    // Extract notification data
    final RemoteNotification? notification = message.notification;

    if (notification != null) {
      _logger.info('Notification Title: ${notification.title}');
      _logger.info('Notification Body: ${notification.body}');
    }
  }

  // Handle notification tap (legacy)
  void _handleNotificationTap(RemoteMessage message) {
    // This can be expanded to handle specific navigation based on the notification type
    _logger.info('Notification tapped: ${message.data}');
  }

  // Save FCM token to Firestore (still used for in-app notifications)
  Future<void> saveToken(String userId) async {
    try {
      // تنظيف معرف المستخدم
      final cleanUserId = userId.trim();
      _logger.info('Attempting to save FCM token for user: $cleanUserId');

      // الحصول على الـ token
      String? token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        _logger.warning(
          'FCM token is null or empty, waiting briefly and trying again...',
        );
        // انتظر لحظة وحاول مرة أخرى
        await Future.delayed(const Duration(seconds: 3));
        token = await _messaging.getToken();

        if (token == null || token.isEmpty) {
          _logger.severe('FCM token still null after retry, cannot save token');
          return;
        }
      }

      _logger.info(
        'Retrieved FCM token for device: ${token.substring(0, min(10, token.length))}..., length: ${token.length}',
      );

      // الحصول على معرف الجهاز
      final deviceId = await _getDeviceIdentifier();
      _logger.info('Device identifier: $deviceId');

      // مرجع لوثيقة المستخدم
      final userDoc = _firestore.collection('users').doc(cleanUserId);

      // إنشاء كائن بيانات الـ token
      final tokenData = {
        'token': token,
        'device': deviceId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': _getPlatformInfo(), // إضافة معلومات المنصة
      };

      // تحديث الوثيقة باستخدام الـ transaction للتأكد من تحديث البيانات بشكل صحيح
      await _firestore.runTransaction((transaction) async {
        // الحصول على بيانات المستخدم الحالية
        final snapshot = await transaction.get(userDoc);

        if (snapshot.exists) {
          _logger.info(
            'User document exists, updating token array via transaction',
          );

          // الحصول على قائمة الـ tokens الحالية (إن وجدت)
          List<Map<String, dynamic>> existingTokens = [];
          final data = snapshot.data() as Map<String, dynamic>;

          if (data.containsKey('fcmTokens')) {
            existingTokens = List<Map<String, dynamic>>.from(
              data['fcmTokens'] ?? [],
            );

            // البحث عن الـ token لنفس الجهاز وإزالته
            existingTokens.removeWhere((item) => item['device'] == deviceId);
            _logger.info('Removed existing token for same device if present');
          }

          // إضافة الـ token الجديد
          existingTokens.add(tokenData);
          _logger.info(
            'Added new token to array, total tokens: ${existingTokens.length}',
          );

          // تحديث الوثيقة
          transaction.update(userDoc, {
            'fcmTokens': existingTokens,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        } else {
          _logger.info(
            'User document does not exist, creating new document with token',
          );

          // إنشاء وثيقة جديدة
          transaction.set(userDoc, {
            'fcmTokens': [tokenData],
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        return null;
      });

      _logger.info(
        'FCM token successfully saved for user: $cleanUserId, device: $deviceId',
      );

      // الاستماع لتحديثات الـ token
      _setupTokenRefreshListener(cleanUserId);
    } catch (e, stackTrace) {
      _logger.severe('Error saving FCM token: $e');
      _logger.severe('Stack trace: $stackTrace');

      // محاولة حفظ الـ token بطريقة بديلة في حالة الفشل
      _fallbackTokenSave(userId);
    }
  }

  // دالة بديلة لحفظ الـ token في حالة فشل الطريقة الأساسية
  Future<void> _fallbackTokenSave(String userId) async {
    try {
      _logger.info('Attempting fallback method to save token');
      final cleanUserId = userId.trim();

      // الحصول على الـ token
      String? token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        _logger.warning('FCM token is null in fallback method');
        return;
      }

      // الحصول على معرف الجهاز
      final deviceId = await _getDeviceIdentifier();

      // مرجع لوثيقة المستخدم
      final userDoc = _firestore.collection('users').doc(cleanUserId);

      // محاولة تحديث الوثيقة مباشرة
      await userDoc.set({
        'fcmTokens': FieldValue.arrayUnion([
          {
            'token': token,
            'device': deviceId,
            'lastUpdated': FieldValue.serverTimestamp(),
            'platform': _getPlatformInfo(),
          },
        ]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.info('Fallback token save successful');
    } catch (e) {
      _logger.severe('Fallback token save failed: $e');
    }
  }

  // إعداد المستمع لتحديث الـ token
  void _setupTokenRefreshListener(String userId) {
    _messaging.onTokenRefresh.listen((String token) {
      _logger.info('FCM token refreshed, updating in database');
      saveToken(userId);
    });
  }

  // الحصول على معلومات المنصة
  String _getPlatformInfo() {
    try {
      return 'Flutter ${Platform.operatingSystem}';
    } catch (e) {
      return 'Flutter unknown';
    }
  }

  // Helper method to get a device identifier
  Future<String> _getDeviceIdentifier() async {
    // This is a simple implementation using the FCM token itself as an identifier
    // In a production app, you might want to use a device info plugin to get more specific info
    final String? instanceId = await _messaging.getToken();
    return instanceId?.substring(0, 16) ?? 'unknown-device';
  }

  // Delete FCM token when logging out
  Future<void> deleteToken(String userId) async {
    try {
      // Get the current token
      String? token = await _messaging.getToken();
      if (token == null) return;

      // Get device identifier
      final deviceId = await _getDeviceIdentifier();

      // Update the Firestore document to remove this specific token
      final userDoc = _firestore.collection('users').doc(userId.trim());

      // Get the current tokens array
      final snapshot = await userDoc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final tokensList = List<Map<String, dynamic>>.from(
        data['fcmTokens'] ?? [],
      );

      // Remove the tokens matching this device
      tokensList.removeWhere(
        (tokenData) =>
            tokenData['device'] == deviceId || tokenData['token'] == token,
      );

      // Update the document with the filtered list
      await userDoc.update({
        'fcmTokens': tokensList,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      // لا تحذف الـ token من الجهاز هنا!
      // await _messaging.deleteToken();
      _logger.info('FCM token deleted for user: $userId, device: $deviceId');
    } catch (e) {
      _logger.severe('Error deleting FCM token: $e');
    }
  }

  // الحصول على قائمة الإشعارات للمستخدم
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    final cleanUserId = userId.trim();
    _logger.info('بدء استعلام Firestore للمستخدم: |$cleanUserId|');

    try {
      // تعديل الاستعلام لإزالة الترتيب الثانوي
      return _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: cleanUserId)
          // تمت إزالة الترتيب بالكامل، سيتم الفرز في الذاكرة بدلاً من ذلك
          .snapshots()
          .map((snapshot) {
            _logger.info(
              'تم استرداد ${snapshot.docs.length} مستند من Firestore',
            );
            _logger.info(
              'معرفات المستندات: ${snapshot.docs.map((doc) => doc.id).toList()}',
            );
            final result =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }).toList();

            // الفرز في الذاكرة بدلاً من استخدام الترتيب في الاستعلام
            result.sort((a, b) {
              final aTimestamp = a['timestamp'] as Timestamp?;
              final bTimestamp = b['timestamp'] as Timestamp?;
              if (aTimestamp == null || bTimestamp == null) return 0;
              return bTimestamp.compareTo(aTimestamp); // ترتيب تنازلي
            });

            return result;
          });
    } catch (e) {
      _logger.severe('خطأ في استعلام Firestore: $e');
      rethrow;
    }
  }

  // الحصول على عدد الإشعارات غير المقروءة
  Stream<int> getUnreadNotificationsCount(String userId) {
    final cleanUserId = userId.trim();
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: cleanUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // إضافة إشعار جديد
  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? additionalData,
    String? targetScreen,
  }) async {
    final cleanUserId = userId.trim();
    try {
      await _firestore.collection(_collectionPath).add({
        'userId': cleanUserId,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'additionalData': additionalData,
        'targetScreen': targetScreen,
      });
    } catch (e) {
      _logger.severe('خطأ في إضافة الإشعار: $e');
      rethrow;
    }
  }

  // تحديث حالة الإشعار لمقروء
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      _logger.severe('خطأ في تحديث حالة الإشعار: $e');
      rethrow;
    }
  }

  // تحديث جميع إشعارات المستخدم كمقروءة
  Future<void> markAllNotificationsAsRead(String userId) async {
    final cleanUserId = userId.trim();
    try {
      // الحصول على جميع الإشعارات غير المقروءة للمستخدم
      final querySnapshot =
          await _firestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: cleanUserId)
              .where('isRead', isEqualTo: false)
              .get();

      // تحديث كل إشعار
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      _logger.severe('خطأ في تحديث حالة جميع الإشعارات: $e');
      rethrow;
    }
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(notificationId).delete();
    } catch (e) {
      _logger.severe('خطأ في حذف الإشعار: $e');
      rethrow;
    }
  }

  // حذف جميع إشعارات المستخدم
  Future<void> deleteAllNotifications(String userId) async {
    final cleanUserId = userId.trim();
    try {
      // الحصول على جميع إشعارات المستخدم
      final querySnapshot =
          await _firestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: cleanUserId)
              .get();

      // حذف كل إشعار
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      _logger.severe('خطأ في حذف جميع الإشعارات: $e');
      rethrow;
    }
  }

  // Function to send push notification via OneSignal
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    String? targetScreen,
  }) async {
    try {
      // First, save the notification to Firestore for in-app access
      await addNotification(
        userId: userId,
        title: title,
        body: body,
        type: type ?? 'general',
        additionalData: data,
        targetScreen: targetScreen,
      );

      _logger.info('In-app notification saved to Firestore for user: $userId');
      _logger.info('Title: $title, Body: $body');

      // We don't need to manually send external notifications anymore
      // OneSignal handles this via the dashboard or the Dashboard API we implemented
      _logger.info('External push notification will be handled by OneSignal');
    } catch (e) {
      _logger.severe('Error in sendPushNotification: $e');
    }
  }

  // إضافة إشعار للمستخدمين المتعددين (للإشعارات الإدارية)
  Future<void> addNotificationToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    String? targetScreen,
    Map<String, dynamic>? additionalData,
  }) async {
    final batch = _firestore.batch();

    for (var userId in userIds) {
      final cleanUserId = userId.trim();
      final newNotificationRef = _firestore.collection(_collectionPath).doc();
      batch.set(newNotificationRef, {
        'userId': cleanUserId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'targetScreen': targetScreen,
        'additionalData': additionalData,
      });
    }

    return batch.commit();
  }

  // حذف الإشعارات القديمة (أقدم من 30 يوماً مثلاً)
  Future<void> deleteOldNotifications(String userId, {int daysOld = 30}) async {
    final cleanUserId = userId.trim();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final timestamp = Timestamp.fromDate(cutoffDate);

    final batch = _firestore.batch();
    final snapshots =
        await _firestore
            .collection(_collectionPath)
            .where('userId', isEqualTo: cleanUserId)
            .where('timestamp', isLessThan: timestamp)
            .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    return batch.commit();
  }
}
