import { Router } from 'express';
import * as registrationController from '../controllers/registrationController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Public routes (accessible to parents and admins)
router.get('/', registrationController.getAllRegistrations);
router.get('/:id/active', registrationController.getActiveRegistrationById);

// Admin routes for registration management
router.post('/', requireAdmin, registrationController.createRegistration);
router.get('/:id', requireAdmin, registrationController.getRegistrationById);
router.put('/:id', requireAdmin, registrationController.updateRegistration);
router.post('/:id/activate', requireAdmin, registrationController.activateRegistration);
router.post('/:id/close', requireAdmin, registrationController.closeRegistration);
router.delete('/:id', requireAdmin, registrationController.deleteRegistration);
export default router;