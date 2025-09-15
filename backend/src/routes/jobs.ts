import express from 'express';
import jobsController from '../controllers/jobsController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = express.Router();

// Health check for jobs API (no auth required for GitHub Actions)
router.get('/health', jobsController.healthCheck);

// Generate weekly rides (admin only for now)
router.post('/generate-weekly-rides', authenticate, requireAdmin, jobsController.generateWeeklyRides);

// Alternative endpoint without auth for GitHub Actions (we'll secure this with API key)
router.post('/scheduled/generate-weekly-rides', jobsController.generateWeeklyRides);

export default router;