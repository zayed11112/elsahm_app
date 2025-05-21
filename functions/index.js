/**
 * Cloud Functions for Firebase - Elsahm App Push Notifications
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin with service account
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Import notification handler
const notificationHandler = require('./src/notifications');

// Function to trigger when a new notification is added to Firestore
exports.sendNotification = functions.firestore
    .document('notifications/{userId}/{notificationId}')
    .onCreate(notificationHandler.handleNewNotification);

// Function to send scheduled notifications (if needed)
exports.sendScheduledNotifications = functions.pubsub
    .schedule('every 15 minutes')
    .onRun(notificationHandler.handleScheduledNotifications);
    
// HTTP function for sending notifications directly from the dashboard
exports.sendNotificationFromDashboard = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }
  
  // Check if the request is a POST request
  if (req.method !== 'POST') {
    res.status(405).send({ error: 'Method Not Allowed. Only POST requests are accepted.' });
    return;
  }
  
  try {
    // Get data from request body
    const { userId, title, body, type = 'general', targetScreen = null, additionalData = null } = req.body;
    
    if (!userId || !title || !body) {
      res.status(400).send({ error: 'Missing required parameters: userId, title, or body' });
      return;
    }
    
    // Create notification document in Firestore
    const notificationRef = admin.firestore()
      .collection('notifications')
      .doc(userId)
      .collection('notifications')
      .doc();
      
    await notificationRef.set({
      userId: userId,
      title: title,
      body: body,
      type: type,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      additionalData: additionalData,
      targetScreen: targetScreen,
    });
    
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      res.status(404).send({ error: 'User not found', userId });
      return;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    
    if (!fcmToken) {
      res.status(404).send({ error: 'FCM token not found for user', userId });
      return;
    }
    
    // Send push notification directly
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type,
        notification_id: notificationRef.id,
        ...(targetScreen && { target_screen: targetScreen }),
      },
      token: fcmToken,
    };
    
    const response = await admin.messaging().send(message);
    
    res.status(200).send({
      success: true,
      message: 'Notification sent successfully',
      notificationId: notificationRef.id,
      fcmResponse: response
    });
    
  } catch (error) {
    functions.logger.error('Error sending notification from dashboard', { error });
    res.status(500).send({
      error: 'Failed to send notification',
      details: error.message
    });
  }
}); 