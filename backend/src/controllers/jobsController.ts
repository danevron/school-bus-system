import { Request, Response } from 'express';
import { log } from '../utils/logger';
import { generateRidesForLine } from '../services/rideGenerationService';
import PushNotificationService from '../services/pushNotificationService';
import Line from '../models/Line';
import Ride, { RideStatus } from '../models/Ride';

class JobsController {
  // Generate weekly rides (placeholder for now)
  async generateWeeklyRides(req: Request, res: Response) {
    try {
      const sevenDaysFromNow = new Date();
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
      const timestamp = new Date().toISOString();
      
      log.info('Generating weekly rides', {
        timestamp,
        targetDate: sevenDaysFromNow.toISOString(),
        triggeredBy: 'github-actions'
      });

      const activeLines = await Line.find({ isActive: true });
    
      let generatedRides = []
      for (const line of activeLines) {
        const rides = await generateRidesForLine(line, sevenDaysFromNow);
        generatedRides.push(...rides);
      }

      const ridesGenerated = Math.floor(Math.random() * 10) + 1;
      
      res.status(200).json({
        message: 'weekly rides generated successfully',
        timestamp,
        targetDate: sevenDaysFromNow.toISOString(),
        generatedRides: generatedRides?.length, 
        jobType: 'generate-weekly-rides'
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      log.error('Failed to generate weekly rides', { error: errorMessage });
      res.status(500).json({
        message: 'Failed to generate weekly rides',
        error: errorMessage
      });
    }
  }

  // Health check specifically for scheduled jobs
  async healthCheck(req: Request, res: Response) {
    try {
      res.status(200).json({
        status: 'OK',
        service: 'School Bus Jobs API',
        timestamp: new Date().toISOString(),
        message: 'Jobs API is ready to receive scheduled tasks'
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      res.status(500).json({
        status: 'ERROR',
        error: errorMessage
      });
    }
  }

  // Ride confirmation messages sending job
  async sendRideConfirmationMessages(req: Request, res: Response) {
    try {
      const timestamp = new Date().toISOString();
      log.info('Starting ride confirmation messages job', { timestamp });

      // Get current time and 2 hours from now
      const now = new Date();
      const twoHoursFromNow = new Date(now.getTime() + (2 * 60 * 60 * 1000));

      // Find all scheduled rides starting in the next 2 hours
      const upcomingRides = await Ride.find({
        startTime: {
          $gte: now,
          $lte: twoHoursFromNow
        },
        status: RideStatus.SCHEDULED
      });

      log.info('Found rides scheduled in the next 2 hours', { 
        ridesCount: upcomingRides.length,
        searchWindow: `${now.toISOString()} to ${twoHoursFromNow.toISOString()}`,
        rideIds: upcomingRides.map(r => r._id?.toString())
      });

      if (upcomingRides.length === 0) {
        res.status(200).json({
          message: 'No rides scheduled in the next 2 hours',
          timestamp,
          searchWindow: `${now.toISOString()} to ${twoHoursFromNow.toISOString()}`,
          ridesProcessed: 0,
          notificationsSent: 0
        });
        return;
      }

      let totalNotificationsSent = 0;
      let totalRecipientsContacted = 0;
      const allErrors: string[] = [];
      const processedRides: string[] = [];

      // Process each ride
      for (const ride of upcomingRides) {
        try {
          log.info('Processing notifications for ride', {
            rideId: ride._id,
            rideStartTime: ride.startTime,
            driver: ride.driver,
            vehicle: ride.vehicle
          });

          const result = await PushNotificationService.sendRideNotifications(ride._id?.toString() || '');
          
          totalNotificationsSent += result.notificationsSent;
          totalRecipientsContacted += result.recipientsContacted.length;
          allErrors.push(...result.errors);
          processedRides.push(ride._id?.toString() || '');

          log.info('Completed notifications for ride', {
            rideId: ride._id,
            notificationsSent: result.notificationsSent,
            recipientsContacted: result.recipientsContacted.length,
            errors: result.errors.length
          });

        } catch (rideError) {
          const errorMsg = `Failed to process ride ${ride._id}: ${rideError}`;
          allErrors.push(errorMsg);
          log.error('Failed to process ride', { rideId: ride._id, error: rideError });
        }
      }

      const successMessage = `Ride confirmation messages job completed`;
      log.info('Ride confirmation messages job completed', {
        timestamp,
        ridesProcessed: processedRides.length,
        totalNotificationsSent,
        totalRecipientsContacted,
        errors: allErrors.length
      });

      res.status(200).json({
        message: successMessage,
        timestamp,
        searchWindow: `${now.toISOString()} to ${twoHoursFromNow.toISOString()}`,
        summary: {
          ridesFound: upcomingRides.length,
          ridesProcessed: processedRides.length,
          notificationsSent: totalNotificationsSent,
          recipientsContacted: totalRecipientsContacted,
          errors: allErrors.length
        },
        processedRides,
        errors: allErrors.length > 0 ? allErrors : undefined
      });

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      log.error('Failed to send ride confirmation messages', { error: errorMessage });
      res.status(500).json({
        message: 'Failed to send ride confirmation messages',
        error: errorMessage,
        timestamp: new Date().toISOString()
      });
    }
  }
}

export default new JobsController();