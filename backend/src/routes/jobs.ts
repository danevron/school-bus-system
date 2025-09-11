import express from 'express';
import jobsController from '../controllers/jobsController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = express.Router();

// Health check for jobs API (no auth required for GitHub Actions)
router.get('/health', jobsController.healthCheck);

// Test job for GitHub Actions (no auth required for now - we'll add API key later)
router.post('/test', jobsController.testJob);

// Generate daily rides (admin only for now)
router.post('/generate-daily-rides', authenticate, requireAdmin, jobsController.generateDailyRides);

// Alternative endpoint without auth for GitHub Actions (we'll secure this with API key)
router.post('/scheduled/generate-daily-rides', jobsController.generateDailyRides);

export default router;