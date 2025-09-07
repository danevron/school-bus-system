import mongoose, { Document, Schema } from 'mongoose';
import { UserRole } from './User';

export enum InvitationStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  EXPIRED = 'expired'
}

export interface IInvitation extends Document {
  email: string;
  phone: string;
  role: UserRole;
  token: string;
  status: InvitationStatus;
  invitedBy: mongoose.Types.ObjectId;
  expiresAt: Date;
  acceptedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  isExpired: () => boolean;
}

const invitationSchema = new Schema<IInvitation>({
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  role: {
    type: String,
    enum: Object.values(UserRole),
    required: true
  },
  token: {
    type: String,
    required: true,
    unique: true
  },
  status: {
    type: String,
    enum: Object.values(InvitationStatus),
    default: InvitationStatus.PENDING
  },
  invitedBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  expiresAt: {
    type: Date,
    required: true,
    default: () => new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days from now
  },
  acceptedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Index for efficient queries
invitationSchema.index({ email: 1 });
// token index is automatically created by unique: true
invitationSchema.index({ status: 1 });
invitationSchema.index({ expiresAt: 1 });

// Check if invitation is expired
invitationSchema.methods.isExpired = function(): boolean {
  return new Date() > this.expiresAt;
};

// Note: Removed problematic pre-hook that was causing find operations to fail
// Instead, expired invitations will be checked manually in controllers

export default mongoose.model<IInvitation>('Invitation', invitationSchema);