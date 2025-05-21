# Firebase Cloud Functions for Push Notifications

This directory contains Firebase Cloud Functions for handling push notifications in the Elsahm App.

## Overview

The main functionality includes:

1. Sending push notifications when a new notification document is added to Firestore
2. Handling scheduled notifications (optional feature)
3. HTTPS endpoint for sending notifications directly from the admin dashboard

## Structure

- `index.js`: Entry point for Cloud Functions
- `src/notifications.js`: Implementation of notification handling logic
- `serviceAccountKey.json`: Service account credentials (not committed to Git)

## Setup

1. Make sure you have the Firebase CLI installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize the project (if not already done):
   ```bash
   firebase init functions
   ```

4. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

## Deploy

To deploy the functions:

```bash
firebase deploy --only functions
```

## Local Testing

You can test the functions locally:

```bash
firebase emulators:start
```

## Firestore Structure

The notifications are stored in the following structure:

```
notifications/{userId}/{notificationId}
```

Each notification document should have the following fields:
- `title`: The title of the notification
- `body`: The content of the notification
- `type`: The notification type (e.g., 'general', 'payment', 'booking')
- `timestamp`: Timestamp when the notification was created
- `isRead`: Boolean indicating whether the notification has been read
- `targetScreen`: (Optional) The screen to navigate to when the notification is tapped
- `additionalData`: (Optional) Any additional data for the notification

## Users Collection

The FCM tokens are stored in the users collection:

```
users/{userId}
```

Each user document should have an `fcmToken` field containing the user's Firebase Cloud Messaging token.

## Dashboard Integration

The function `sendNotificationFromDashboard` provides an HTTP endpoint for sending notifications directly from the admin dashboard.

### Using the API Endpoint

After deploying, the endpoint will be available at:
```
https://[REGION]-[PROJECT-ID].cloudfunctions.net/sendNotificationFromDashboard
```

### Request Format

Send a POST request with the following JSON structure:

```json
{
  "userId": "USER_ID",
  "title": "Notification Title",
  "body": "Notification Content",
  "type": "payment",
  "targetScreen": "walletScreen",
  "additionalData": {
    "amount": 2000,
    "currency": "EGP"
  }
}
```

Required fields:
- `userId`: ID of the user to send the notification to
- `title`: Title of the notification
- `body`: Content of the notification

Optional fields:
- `type`: Type of notification (default: "general")
- `targetScreen`: Screen to navigate to when notification is tapped
- `additionalData`: Any additional data to include with the notification

### Response Format

Success response (200 OK):
```json
{
  "success": true,
  "message": "Notification sent successfully",
  "notificationId": "NOTIFICATION_ID",
  "fcmResponse": "FCM_MESSAGE_ID"
}
```

Error response (4xx or 5xx):
```json
{
  "error": "Error message",
  "details": "Detailed error information"
}
```

## Security Note

The service account key (`serviceAccountKey.json`) contains sensitive information and should **not** be committed to source control. It's already added to `.gitignore`. 