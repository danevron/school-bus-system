import mongoose, { Document, Schema } from 'mongoose';

export interface ISelectedStop {
  name: string;
  description?: string;
}

export interface IRegistrationRequest extends Document {
  registration: mongoose.Types.ObjectId;
  parent: mongoose.Types.ObjectId;
  student: mongoose.Types.ObjectId; // Reference to existing student
  address: string; // Student's address for this registration
  selectedStop: ISelectedStop;
  comments?: string;
  createdAt: Date;
  updatedAt: Date;
}

const selectedStopSchema = new Schema<ISelectedStop>({
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

const registrationRequestSchema = new Schema<IRegistrationRequest>({
  registration: {
    type: Schema.Types.ObjectId,
    ref: 'Registration',
    required: true
  },
  parent: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  student: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  address: {
    type: String,
    required: true,
    trim: true
  },
  selectedStop: {
    type: selectedStopSchema,
    required: true
  },
  comments: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Index for efficient querying
registrationRequestSchema.index({ registration: 1 });
registrationRequestSchema.index({ parent: 1 });
registrationRequestSchema.index({ registration: 1, student: 1 }, { unique: true }); // One request per student per registration

export default mongoose.model<IRegistrationRequest>('RegistrationRequest', registrationRequestSchema);