import { Router } from 'express';
import * as registrationRequestController from '../controllers/registrationRequestController';
import { authenticate, requireAdmin, requireParent } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Public routes (authenticated users)
router.get('/active-registrations', registrationRequestController.getActiveRegistrations);

// Parent routes
router.post('/:registrationId', requireParent, registrationRequestController.submitRegistrationRequest);
router.get('/my-requests', requireParent, registrationRequestController.getMyRegistrationRequests);
router.get('/:id', registrationRequestController.getRegistrationRequestById); // Uses role check inside controller
router.put('/:id', requireParent, registrationRequestController.updateRegistrationRequest);
router.delete('/:id', registrationRequestController.deleteRegistrationRequest); // Uses role check inside controller

// Admin routes
router.get('/', requireAdmin, registrationRequestController.getAllRegistrationRequests);

export default router;