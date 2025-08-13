import { Router } from 'express';
import * as rideController from '../controllers/rideController';
import { authenticate, requireAdmin, requireDriver, requireParent, requireStudent } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin routes
router.post('/generate', requireAdmin, rideController.generateRides);
router.get('/', requireAdmin, rideController.getAllRides);
router.get('/:id', requireAdmin, rideController.getRideById);
router.put('/:id/status', requireAdmin, rideController.updateRideStatus);
router.post('/:rideId/guests', requireAdmin, rideController.addGuestStudent);

// Driver routes
router.get('/driver/my-rides', requireDriver, rideController.getDriverRides);
router.put('/:id/status', requireDriver, rideController.updateRideStatus);
router.put('/:rideId/students/:studentId/status', requireDriver, rideController.updateStudentStatus);

// Parent routes
router.delete('/:rideId/students/:studentId', requireParent, rideController.removeStudentFromRide);

// Student routes
router.get('/student/my-rides', requireStudent, rideController.getStudentRides);

export default router; 