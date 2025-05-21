/**
 * Notification handlers for Firebase Cloud Functions
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Handle a new notification document and send push notification
 * @param {Object} snapshot - Firestore document snapshot
 * @param {Object} context - Function context
 * @return {Promise}
 */
exports.handleNewNotification = async (snapshot, context) => {
  try {
    const notificationData = snapshot.data();
    const userId = context.params.userId;
    const notificationId = context.params.notificationId;

    // Log for debugging
    functions.logger.info('New notification created', {
      userId,
      notificationId,
      notificationData,
    });

    // Get user's FCM token from Firestore
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      functions.logger.warn('User document not found', { userId });
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      functions.logger.warn('FCM token not found for user', { userId });
      return null;
    }

    // Get notification data
    const title = notificationData.title || 'تنبيه جديد';
    const body = notificationData.body || '';
    const type = notificationData.type || 'general';
    const targetScreen = notificationData.targetScreen || null;

    // Build notification message
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type,
        ...(targetScreen && { target_screen: targetScreen }),
        notification_id: notificationId,
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          priority: 'high',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Send the notification
    const response = await admin.messaging().send(message);
    functions.logger.info('Notification sent successfully', { response });
    
    return response;
  } catch (error) {
    functions.logger.error('Error sending notification', { error });
    return null;
  }
};

/**
 * Handle scheduled notifications (for future use)
 * @return {Promise}
 */
exports.handleScheduledNotifications = async () => {
  try {
    // Check if there are any scheduled notifications to send
    const now = admin.firestore.Timestamp.now();
    
    // Query for notifications that are scheduled to be sent now
    const scheduledNotificationsQuery = await admin.firestore()
      .collectionGroup('scheduledNotifications')
      .where('scheduledTime', '<=', now)
      .where('sent', '==', false)
      .limit(50) // Process in batches
      .get();
    
    if (scheduledNotificationsQuery.empty) {
      functions.logger.info('No scheduled notifications to send');
      return null;
    }
    
    const sendPromises = [];
    const batch = admin.firestore().batch();
    
    scheduledNotificationsQuery.forEach((doc) => {
      const notification = doc.data();
      
      // Create a regular notification
      const notificationRef = admin.firestore()
        .collection('notifications')
        .doc(notification.userId)
        .collection('notifications')
        .doc();
      
      batch.set(notificationRef, {
        userId: notification.userId,
        title: notification.title,
        body: notification.body,
        type: notification.type || 'general',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        additionalData: notification.additionalData || null,
        targetScreen: notification.targetScreen || null,
      });
      
      // Mark the scheduled notification as sent
      batch.update(doc.ref, { sent: true });
    });
    
    await batch.commit();
    functions.logger.info('Scheduled notifications processed', {
      count: scheduledNotificationsQuery.size,
    });
    
    return { count: scheduledNotificationsQuery.size };
  } catch (error) {
    functions.logger.error('Error processing scheduled notifications', { error });
    return null;
  }
}; 