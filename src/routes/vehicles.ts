import { Router } from 'express';
import * as vehicleController from '../controllers/vehicleController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin routes
router.post('/', requireAdmin, vehicleController.createVehicle);
router.put('/:id', requireAdmin, vehicleController.updateVehicle);
router.delete('/:id', requireAdmin, vehicleController.deleteVehicle);

// Public routes (for authenticated users)
router.get('/', vehicleController.getAllVehicles);
router.get('/:id', vehicleController.getVehicleById);

export default router; 