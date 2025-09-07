import { Router } from 'express';
import * as lineController from '../controllers/lineController';
import { authenticate, requireAdmin, requireDriver } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin routes
router.post('/', requireAdmin, lineController.createLine);
router.put('/:id', requireAdmin, lineController.updateLine);
router.delete('/:id', requireAdmin, lineController.deleteLine);
router.post('/:id/activate', requireAdmin, lineController.activateLine);
router.post('/:id/assign-students', requireAdmin, lineController.assignStudentsToLine);
router.post('/:id/students', requireAdmin, lineController.addStudentToLine);
router.delete('/:id/students/:studentId', requireAdmin, lineController.removeStudentFromLine);

// Route management endpoints (formerly standalone routes)
router.put('/:id/route', requireAdmin, lineController.updateLineRoute);
router.delete('/:id/route', requireAdmin, lineController.removeLineRoute);

// Stop management endpoints (formerly in route controller)
router.post('/:id/route/stops', requireAdmin, lineController.addStopToLineRoute);
router.put('/:id/route/stops', requireAdmin, lineController.updateLineRouteStops);
router.delete('/:id/route/stops/:stopIndex', requireAdmin, lineController.deleteStopFromLineRoute);

// Student assignment management endpoints
router.post('/:id/student-assignments', requireAdmin, lineController.assignStudentToLineWithStops);
router.get('/:id/student-assignments', lineController.getLineStudentAssignments);
router.put('/:id/student-assignments/:assignmentId', requireAdmin, lineController.updateStudentAssignment);
router.delete('/:id/student-assignments/:assignmentId', requireAdmin, lineController.removeStudentAssignment);

// Stop usage information endpoint
router.get('/:id/stop-usage', lineController.getStopUsageInfo);

// Public routes (for authenticated users)
router.get('/', lineController.getAllLines);
router.get('/:id', lineController.getLineById);

// Driver routes
router.get('/driver/my-lines', requireDriver, lineController.getLinesByDriver);

export default router; 