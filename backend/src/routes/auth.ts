import { Router } from 'express';
import * as authController from '../controllers/authController';
import { authenticate, requireAdmin, requireParent } from '../middlewares/auth';

const router = Router();

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Protected routes
router.get('/profile', authenticate, authController.getProfile);

// Parent routes
router.get('/my-students', authenticate, requireParent, authController.getMyStudents);
router.post('/my-students', authenticate, requireParent, authController.createStudentForParent);

// Admin routes
router.get('/users', authenticate, requireAdmin, authController.getAllUsers);
router.post('/students', authenticate, requireAdmin, authController.createStudent);
router.get('/students/with-parents', authenticate, requireAdmin, authController.getStudentsWithParentInfo);
router.post('/students/connect-parents', authenticate, requireAdmin, authController.connectStudentToParents);

export default router; 