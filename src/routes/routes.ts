import { Router } from 'express';
import * as routeController from '../controllers/routeController';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin routes
router.post('/', requireAdmin, routeController.createRoute);
router.put('/:id', requireAdmin, routeController.updateRoute);
router.delete('/:id', requireAdmin, routeController.deleteRoute);

// Stop management routes (admin only)
router.post('/:id/stops', requireAdmin, routeController.addStopToRoute);
router.put('/:id/stops', requireAdmin, routeController.updateRouteStops);
router.delete('/:id/stops/:stopIndex', requireAdmin, routeController.deleteStopFromRoute);

// Public routes (for authenticated users)
router.get('/', routeController.getAllRoutes);
router.get('/:id', routeController.getRouteById);

export default router; 