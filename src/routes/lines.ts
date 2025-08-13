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
router.post('/:id/assign-students', requireAdmin, lineController.assignStudentsToLine);
router.post('/:id/students', requireAdmin, lineController.addStudentToLine);
router.delete('/:id/students/:studentId', requireAdmin, lineController.removeStudentFromLine);

// Public routes (for authenticated users)
router.get('/', lineController.getAllLines);
router.get('/:id', lineController.getLineById);

// Driver routes
router.get('/driver/my-lines', requireDriver, lineController.getLinesByDriver);

export default router; 