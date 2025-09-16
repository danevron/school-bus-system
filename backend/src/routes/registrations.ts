import { Router } from 'express';
import * as registrationController from '../controllers/registrationController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin routes for registration management
router.post('/', requireAdmin, registrationController.createRegistration);
router.get('/', requireAdmin, registrationController.getAllRegistrations);
router.get('/:id', requireAdmin, registrationController.getRegistrationById);
router.put('/:id', requireAdmin, registrationController.updateRegistration);
router.post('/:id/activate', requireAdmin, registrationController.activateRegistration);
router.post('/:id/close', requireAdmin, registrationController.closeRegistration);
router.delete('/:id', requireAdmin, registrationController.deleteRegistration);

export default router;