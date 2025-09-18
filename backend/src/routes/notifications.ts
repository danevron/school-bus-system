import { Router } from 'express';
import * as notificationController from '../controllers/notificationController';
import { authenticate } from '../middlewares/auth';

const router = Router();

// All notification routes require authentication
router.post('/register-token', authenticate, notificationController.registerToken);
router.get('/my-tokens', authenticate, notificationController.getUserTokens);
router.post('/deactivate-token', authenticate, notificationController.deactivateToken);

export default router;