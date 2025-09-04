import express from 'express';
import { rideController } from '../controllers/rideController';
import { requireAuth, requireAdmin, requireDriver } from '../middlewares/auth';

const router = express.Router();

// Apply authentication to all routes
router.use(requireAuth);

// Admin-only routes
router.get('/', requireAdmin, rideController.getAllRides);
router.post('/', requireAdmin, rideController.createRide);
router.put('/:id', requireAdmin, rideController.updateRide);
router.delete('/:id', requireAdmin, rideController.deleteRide);

// Routes accessible by Admin and Driver
router.get('/:id', rideController.getRideById);

// Driver-specific routes
router.get('/driver/my-rides', requireDriver, rideController.getDriverRides);
router.post('/:id/start', requireDriver, rideController.startRide);
router.post('/:id/end', requireDriver, rideController.endRide);

export default router;