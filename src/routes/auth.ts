import { Router } from 'express';
import * as authController from '../controllers/authController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Protected routes
router.get('/profile', authenticate, authController.getProfile);

// Admin routes
router.get('/users', authenticate, requireAdmin, authController.getAllUsers);

export default router; 