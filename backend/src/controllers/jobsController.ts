import { Request, Response } from 'express';
import { log } from '../utils/logger';
import { generateRidesForLine } from '../services/rideGenerationService';
import Line from '../models/Line';

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
}

export default new JobsController();