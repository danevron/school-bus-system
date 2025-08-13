import mongoose, { Document, Schema, Types } from 'mongoose';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
  COMPLETED = 'completed'
}

export interface IBooking extends Document {
  student: Types.ObjectId;
  parent: Types.ObjectId;
  line: Types.ObjectId;
  date: Date;
  pickupStop: Types.ObjectId;
  dropoffStop: Types.ObjectId;
  status: BookingStatus;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const bookingSchema = new Schema<IBooking>({
  student: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  parent: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  line: {
    type: Schema.Types.ObjectId,
    ref: 'Line',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  pickupStop: {
    type: Schema.Types.ObjectId,
    required: true
  },
  dropoffStop: {
    type: Schema.Types.ObjectId,
    required: true
  },
  status: {
    type: String,
    enum: Object.values(BookingStatus),
    default: BookingStatus.PENDING
  },
  notes: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Index for efficient queries
bookingSchema.index({ student: 1, date: 1 });
bookingSchema.index({ line: 1, date: 1 });
bookingSchema.index({ status: 1 });

export default mongoose.model<IBooking>('Booking', bookingSchema); 