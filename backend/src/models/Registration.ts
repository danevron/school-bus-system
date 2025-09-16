import mongoose, { Document, Schema } from 'mongoose';

export enum RegistrationType {
  PICKUP = 'pickup',
  RETURN = 'return'
}

export enum RegistrationStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  CLOSED = 'closed'
}

export interface IStop {
  name: string;
  description?: string;
}

export interface IRegistration extends Document {
  title: string;
  description?: string;
  type: RegistrationType;
  status: RegistrationStatus;
  stops: IStop[];
  activatedAt?: Date;
  closedAt?: Date;
  createdBy: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const stopSchema = new Schema<IStop>({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  }
}, { _id: false });

const registrationSchema = new Schema<IRegistration>({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  type: {
    type: String,
    enum: Object.values(RegistrationType),
    required: true
  },
  status: {
    type: String,
    enum: Object.values(RegistrationStatus),
    default: RegistrationStatus.DRAFT
  },
  stops: {
    type: [stopSchema],
    required: true,
    validate: {
      validator: function(value: IStop[]) {
        return Array.isArray(value) && value.length > 0;
      },
      message: 'At least one stop must be provided'
    }
  },
  activatedAt: {
    type: Date
  },
  closedAt: {
    type: Date
  },
  createdBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

// Index for efficient querying
registrationSchema.index({ status: 1, type: 1 });
registrationSchema.index({ createdBy: 1 });

// Pre-save middleware to set activation/closure timestamps
registrationSchema.pre('save', function(next) {
  if (this.isModified('status')) {
    if (this.status === RegistrationStatus.ACTIVE && !this.activatedAt) {
      this.activatedAt = new Date();
    } else if (this.status === RegistrationStatus.CLOSED && !this.closedAt) {
      this.closedAt = new Date();
    }
  }
  next();
});

export default mongoose.model<IRegistration>('Registration', registrationSchema);