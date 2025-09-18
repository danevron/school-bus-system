// Test script to send push notifications
// Run this from your backend directory: node ../mobile/test_notification.js

const admin = require('firebase-admin');

// Initialize Firebase Admin (you'll need your service account key)
// Download it from Firebase Console > Project Settings > Service Accounts
const serviceAccount = require('./path/to/your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function sendTestNotification() {
  const message = {
    notification: {
      title: 'Ride Confirmation Required',
      body: 'Please confirm your booking for tomorrow\'s ride',
    },
    data: {
      rideId: 'YOUR_TEST_RIDE_ID',
      bookingId: 'YOUR_TEST_BOOKING_ID',
      action: 'confirm_booking',
    },
    // Replace with the FCM token from your app logs
    token: 'YOUR_DEVICE_FCM_TOKEN',
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent notification:', response);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

sendTestNotification();