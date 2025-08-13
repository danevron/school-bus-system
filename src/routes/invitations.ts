import express from 'express';
import { authenticate, requireAdmin } from '../middlewares/auth';
import { 
  inviteUser, 
  getInvitations, 
  getInvitationByToken, 
  acceptInvitation, 
  deleteInvitation 
} from '../controllers/invitationController';

const router = express.Router();

// Admin routes - require authentication and admin role
router.post('/', authenticate, requireAdmin, inviteUser);
router.get('/', authenticate, requireAdmin, getInvitations);
router.delete('/:id', authenticate, requireAdmin, deleteInvitation);

// Public routes - for accepting invitations
router.get('/token/:token', getInvitationByToken);
router.post('/accept/:token', acceptInvitation);

export default router;