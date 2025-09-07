import { Request, Response } from 'express';
import crypto from 'crypto';
import Invitation, { InvitationStatus } from '../models/Invitation';
import User, { UserRole } from '../models/User';
import { EmailService } from '../services/emailService';
import { validateInviteUser, validateAcceptInvitation } from '../utils/validation';
import { log } from '../utils/logger';

export const inviteUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = validateInviteUser(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { email, phone, role } = req.body;
    const inviterId = req.user!.userId;
    log.debug('Processing user invitation', { email, role, inviterId });

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ message: 'User with this email already exists' });
      return;
    }

    // Check if there's already a pending invitation
    const existingInvitation = await Invitation.findOne({ 
      email, 
      status: InvitationStatus.PENDING 
    });
    
    if (existingInvitation && !existingInvitation.isExpired()) {
      res.status(400).json({ message: 'Pending invitation already exists for this email' });
      return;
    }

    // Generate secure token
    const token = crypto.randomBytes(32).toString('hex');

    // Create invitation
    const invitation = new Invitation({
      email,
      phone,
      role,
      token,
      invitedBy: inviterId
    });

    await invitation.save();

    // Get inviter info for email
    const inviter = await User.findById(inviterId);
    const inviterName = `${inviter?.firstName} ${inviter?.lastName}`;
    log.debug('Sending invitation email', { email, inviterName, role });

    // Send invitation email
    const emailSent = await EmailService.sendInvitation(
      email,
      inviterName,
      role,
      token
    );

    if (!emailSent) {
      log.warn('Failed to send invitation email, but invitation was created', { email, role });
    }

    res.status(201).json({
      message: 'Invitation sent successfully',
      invitation: {
        id: invitation._id,
        email: invitation.email,
        phone: invitation.phone,
        role: invitation.role,
        status: invitation.status,
        expiresAt: invitation.expiresAt,
        invitedBy: inviterName,
        createdAt: invitation.createdAt
      }
    });

  } catch (error) {
    log.error('Error inviting user', { 
      email: req.body.email, 
      role: req.body.role, 
      error: error instanceof Error ? error.message : error 
    });
    res.status(500).json({ 
      message: 'Failed to send invitation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : 'Internal server error'
    });
  }
};

export const getInvitations = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, role } = req.query;
    
    const filter: any = {};
    if (status) filter.status = status;
    if (role) filter.role = role;

    const invitations = await Invitation.find(filter)
      .populate('invitedBy', 'firstName lastName email')
      .sort({ createdAt: -1 });

    res.json({ invitations });

  } catch (error) {
    log.error('Error fetching invitations', { 
      error: error instanceof Error ? error.message : error 
    });
    res.status(500).json({ 
      message: 'Failed to fetch invitations',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : 'Internal server error'
    });
  }
};

export const getInvitationByToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token } = req.params;

    const invitation = await Invitation.findOne({ token })
      .populate('invitedBy', 'firstName lastName email');

    if (!invitation) {
      res.status(404).json({ message: 'Invitation not found' });
      return;
    }

    if (invitation.status !== InvitationStatus.PENDING) {
      res.status(400).json({ message: 'Invitation is no longer valid' });
      return;
    }

    if (invitation.isExpired()) {
      invitation.status = InvitationStatus.EXPIRED;
      await invitation.save();
      res.status(400).json({ message: 'Invitation has expired' });
      return;
    }

    res.json({
      invitation: {
        email: invitation.email,
        phone: invitation.phone,
        role: invitation.role,
        invitedBy: `${(invitation.invitedBy as any).firstName} ${(invitation.invitedBy as any).lastName}`,
        expiresAt: invitation.expiresAt
      }
    });

  } catch (error) {
    log.error('Error fetching invitation by token', { 
      token: req.params.token,
      error: error instanceof Error ? error.message : error 
    });
    res.status(500).json({ 
      message: 'Failed to fetch invitation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : 'Internal server error'
    });
  }
};

export const acceptInvitation = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token } = req.params;
    const { firstName, lastName, password } = req.body;

    const { error } = validateAcceptInvitation({ firstName, lastName, password });
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    // Find invitation
    const invitation = await Invitation.findOne({ token });
    
    if (!invitation) {
      res.status(404).json({ message: 'Invitation not found' });
      return;
    }

    if (invitation.status !== InvitationStatus.PENDING) {
      res.status(400).json({ message: 'Invitation is no longer valid' });
      return;
    }

    if (invitation.isExpired()) {
      invitation.status = InvitationStatus.EXPIRED;
      await invitation.save();
      res.status(400).json({ message: 'Invitation has expired' });
      return;
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: invitation.email });
    if (existingUser) {
      res.status(400).json({ message: 'User already exists' });
      return;
    }

    // Create user
    const user = new User({
      email: invitation.email,
      password,
      firstName,
      lastName,
      phone: invitation.phone,
      role: invitation.role
    });

    await user.save();

    // Update invitation status
    invitation.status = InvitationStatus.ACCEPTED;
    invitation.acceptedAt = new Date();
    await invitation.save();

    res.status(201).json({
      message: 'Account created successfully',
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        role: user.role
      }
    });

  } catch (error) {
    log.error('Error accepting invitation', { 
      token: req.params.token,
      error: error instanceof Error ? error.message : error 
    });
    res.status(500).json({ 
      message: 'Failed to accept invitation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : 'Internal server error'
    });
  }
};

export const deleteInvitation = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const invitation = await Invitation.findByIdAndDelete(id);

    if (!invitation) {
      res.status(404).json({ message: 'Invitation not found' });
      return;
    }

    res.json({ message: 'Invitation deleted successfully' });

  } catch (error) {
    log.error('Error deleting invitation', { 
      invitationId: req.params.id,
      error: error instanceof Error ? error.message : error 
    });
    res.status(500).json({ 
      message: 'Failed to delete invitation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : 'Internal server error'
    });
  }
};