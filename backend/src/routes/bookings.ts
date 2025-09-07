import express from 'express';
import { bookingController } from '../controllers/bookingController';
import { requireAuth, requireAdmin, requireDriver } from '../middlewares/auth';

const router = express.Router();

// Apply authentication to all routes
router.use(requireAuth);

// Admin-only routes
router.get('/', requireAdmin, bookingController.getAllBookings);
router.post('/:id/confirm', requireAdmin, bookingController.confirmBooking);
router.post('/:id/admit', requireAdmin, bookingController.admitWaitingListBooking);

// Routes accessible by multiple roles
router.get('/:id', bookingController.getBookingById);
router.post('/', bookingController.createBooking);
router.post('/:id/cancel', bookingController.cancelBooking);

// Driver-specific routes
router.post('/:id/checkin', requireDriver, bookingController.checkInPassenger);
router.post('/:id/dropoff', requireDriver, bookingController.dropOffPassenger);
router.get('/ride/:rideId', bookingController.getRideBookings);

// User-specific routes (any authenticated user can access their own bookings)
router.get('/user/:userId', bookingController.getUserBookings);

export default router;