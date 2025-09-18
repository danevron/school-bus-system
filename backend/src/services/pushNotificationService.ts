import admin from 'firebase-admin';
import { log } from '../utils/logger';
import DeviceToken from '../models/DeviceToken';
import Booking, { BookingStatus } from '../models/Booking';
import Ride from '../models/Ride';
import User, { UserRole } from '../models/User';
import mongoose from 'mongoose';

// Initialize Firebase Admin SDK
let firebaseInitialized = false;

const initializeFirebase = () => {
  if (!firebaseInitialized && !admin.apps.length) {
    try {
      // In production, you would use a service account key file or environment variables
      // For now, we'll initialize with default credentials
      admin.initializeApp();
      firebaseInitialized = true;
      log.info('Firebase Admin SDK initialized successfully');
    } catch (error) {
      log.error('Failed to initialize Firebase Admin SDK', { error });
    }
  }
};

export interface NotificationMessage {
  title: string;
  body: string;
  data?: { [key: string]: string };
}

export interface NotificationRecipient {
  userId: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  relationship?: string; // e.g., 'passenger', 'parent', 'inviter'
}

export class PushNotificationService {
  
  /**
   * Send push notification to specific FCM tokens
   */
  static async sendToTokens(
    tokens: string[], 
    message: NotificationMessage
  ): Promise<{ success: number; failure: number; invalidTokens: string[] }> {
    if (!firebaseInitialized) {
      initializeFirebase();
    }

    if (tokens.length === 0) {
      log.warn('No tokens provided for push notification');
      return { success: 0, failure: 0, invalidTokens: [] };
    }

    try {
      const messaging = admin.messaging();
      const multicastMessage = {
        notification: {
          title: message.title,
          body: message.body
        },
        data: message.data || {},
        tokens: tokens
      };

      const response = await messaging.sendEachForMulticast(multicastMessage);
      
      // Track invalid tokens for cleanup
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && 
            (resp.error?.code === 'messaging/invalid-registration-token' ||
             resp.error?.code === 'messaging/registration-token-not-registered')) {
          invalidTokens.push(tokens[idx]);
        }
      });

      // Clean up invalid tokens
      if (invalidTokens.length > 0) {
        await this.deactivateInvalidTokens(invalidTokens);
      }

      log.info('Push notification sent', {
        successCount: response.successCount,
        failureCount: response.failureCount,
        invalidTokens: invalidTokens.length
      });

      return {
        success: response.successCount,
        failure: response.failureCount,
        invalidTokens
      };

    } catch (error) {
      log.error('Failed to send push notification', { error, tokens });
      return { success: 0, failure: tokens.length, invalidTokens: [] };
    }
  }

  /**
   * Send notification to a specific user (all their active devices)
   */
  static async sendToUser(userId: string, message: NotificationMessage): Promise<boolean> {
    try {
      const deviceTokens = await DeviceToken.find({
        userId: new mongoose.Types.ObjectId(userId),
        isActive: true
      });

      if (deviceTokens.length === 0) {
        log.warn('No active device tokens found for user', { userId });
        return false;
      }

      const tokens = deviceTokens.map(dt => dt.fcmToken);
      const result = await this.sendToTokens(tokens, message);
      
      return result.success > 0;
    } catch (error) {
      log.error('Failed to send notification to user', { error, userId });
      return false;
    }
  }

  /**
   * Send ride confirmation notification for a specific ride
   * Gets all bookings and notifies passengers, parents, and inviters
   */
  static async sendRideNotifications(rideId: string): Promise<{
    notificationsSent: number;
    recipientsContacted: NotificationRecipient[];
    errors: string[];
  }> {
    const errors: string[] = [];
    const recipientsContacted: NotificationRecipient[] = [];
    let notificationsSent = 0;

    try {
      // Get ride details
      const ride = await Ride.findById(rideId)
        .populate('driver', 'firstName lastName')
        .populate('vehicle', 'plateNumber model');

      if (!ride) {
        throw new Error(`Ride not found: ${rideId}`);
      }

      // Get all active bookings for this ride
      const bookings = await Booking.find({
        ride: rideId,
        status: { $in: [BookingStatus.UNCONFIRMED] }
      }).populate('passenger', 'firstName lastName role parents invitedBy isGuest');

      if (bookings.length === 0) {
        log.info('No active bookings found for ride', { rideId });
        return { notificationsSent: 0, recipientsContacted: [], errors: [] };
      }

      // Prepare notification message
      const rideDate = ride.date.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });

      const message: NotificationMessage = {
        title: 'Ride Confirmation Required',
        body: `Please confirm your ride for ${rideDate}. Tap to view details.`,
        data: {
          rideId: rideId,
          type: 'ride_confirmation',
          action: 'confirm_ride'
        }
      };

      // Process each booking
      for (const booking of bookings) {
        const passenger = booking.passenger as any; // Type assertion since it's populated
        const uniqueUserIds = new Set<string>();

        try {
          // Add passenger (if not a guest student)
          if (passenger.role !== UserRole.STUDENT || !passenger.isGuest) {
            uniqueUserIds.add(passenger._id.toString());
            recipientsContacted.push({
              userId: passenger._id.toString(),
              firstName: passenger.firstName,
              lastName: passenger.lastName,
              role: passenger.role,
              relationship: 'passenger'
            });
          }

          // Add parents (for students)
          if (passenger.role === UserRole.STUDENT && passenger.parents) {
            for (const parentId of passenger.parents) {
              const parent = await User.findById(parentId);
              if (parent && parent.isActive) {
                uniqueUserIds.add(parent._id?.toString() || '');
                recipientsContacted.push({
                  userId: parent._id?.toString() || '',
                  firstName: parent.firstName,
                  lastName: parent.lastName,
                  role: parent.role,
                  relationship: 'parent'
                });
              }
            }
          }

          // Add inviter (for guest users)
          if (passenger.isGuest && passenger.invitedBy) {
            const inviter = await User.findById(passenger.invitedBy);
            if (inviter && inviter.isActive) {
              uniqueUserIds.add(inviter._id?.toString() || '');
              recipientsContacted.push({
                userId: inviter._id?.toString() || '',
                firstName: inviter.firstName,
                lastName: inviter.lastName,
                role: inviter.role,
                relationship: 'inviter'
              });
            }
          }

          // Send notifications to all unique users
          for (const userId of uniqueUserIds) {
            const bookingMessage = {
              ...message,
              data: {
                ...message.data,
                bookingId: booking._id?.toString() || '',
                passengerId: passenger._id.toString(),
                passengerName: `${passenger.firstName} ${passenger.lastName}`
              }
            };

            const success = await this.sendToUser(userId, bookingMessage);
            if (success) {
              notificationsSent++;
            }
          }

        } catch (bookingError) {
          const errorMsg = `Failed to process booking ${booking._id}: ${bookingError}`;
          errors.push(errorMsg);
          log.error('Failed to process booking', { bookingId: booking._id?.toString(), error: bookingError });
        }
      }

      log.info('Ride notifications completed', {
        rideId,
        bookingsProcessed: bookings.length,
        notificationsSent,
        recipientsContacted: recipientsContacted.length,
        errors: errors.length
      });

      return {
        notificationsSent,
        recipientsContacted,
        errors
      };

    } catch (error) {
      const errorMsg = `Failed to send ride notifications: ${error}`;
      errors.push(errorMsg);
      log.error('Failed to send ride notifications', { rideId, error });
      
      return {
        notificationsSent,
        recipientsContacted,
        errors
      };
    }
  }

  /**
   * Deactivate invalid FCM tokens
   */
  private static async deactivateInvalidTokens(invalidTokens: string[]): Promise<void> {
    try {
      await DeviceToken.updateMany(
        { fcmToken: { $in: invalidTokens } },
        { isActive: false }
      );
      
      log.info('Deactivated invalid FCM tokens', { count: invalidTokens.length });
    } catch (error) {
      log.error('Failed to deactivate invalid tokens', { error, invalidTokens });
    }
  }

  /**
   * Test notification sending (for development/testing)
   */
  static async sendTestNotification(userId: string): Promise<boolean> {
    const message: NotificationMessage = {
      title: 'Test Notification',
      body: 'This is a test push notification from the School Bus System.',
      data: {
        type: 'test',
        timestamp: new Date().toISOString()
      }
    };

    return await this.sendToUser(userId, message);
  }
}

export default PushNotificationService;