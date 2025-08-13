import { Router } from 'express';
import * as bookingController from '../controllers/bookingController';
import { authenticate, requireAdmin, requireParent } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin routes
router.get('/', requireAdmin, bookingController.getAllBookings);
router.get('/:id', requireAdmin, bookingController.getBookingById);
router.put('/:id', requireAdmin, bookingController.updateBooking);

// Parent routes
router.post('/', requireParent, bookingController.createBooking);
router.get('/parent/my-bookings', requireParent, bookingController.getBookingsByParent);

// Line-specific bookings (for drivers and admins)
router.get('/line/:lineId', bookingController.getBookingsByLine);

export default router; 