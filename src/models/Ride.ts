import mongoose, { Document, Schema, Types } from 'mongoose';

export enum RideStatus {
  SCHEDULED = 'scheduled',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

export enum StudentRideStatus {
  PENDING = 'pending',
  PICKED_UP = 'picked_up',
  DROPPED_OFF = 'dropped_off',
  ABSENT = 'absent'
}

export interface IStudentRide {
  student: Types.ObjectId;
  status: StudentRideStatus;
  pickupTime?: Date;
  dropoffTime?: Date;
  pickupStop: string; // Now references stopId instead of ObjectId
  dropoffStop: string; // Now references stopId instead of ObjectId
  notes?: string;
}

export interface IGuestStudent {
  firstName: string;
  lastName: string;
  phone: string;
  pickupStop: string; // Now references stopId instead of ObjectId
  dropoffStop: string; // Now references stopId instead of ObjectId
  status: StudentRideStatus;
  pickupTime?: Date;
  dropoffTime?: Date;
  notes?: string;
}

export interface IRide extends Document {
  line: Types.ObjectId;
  date: Date;
  status: RideStatus;
  startTime?: Date;
  endTime?: Date;
  students: IStudentRide[];
  guests: IGuestStudent[];
  driver: Types.ObjectId;
  vehicle: Types.ObjectId;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const studentRideSchema = new Schema<IStudentRide>({
  student: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: Object.values(StudentRideStatus),
    default: StudentRideStatus.PENDING
  },
  pickupTime: {
    type: Date
  },
  dropoffTime: {
    type: Date
  },
  pickupStop: {
    type: String,
    required: true
  },
  dropoffStop: {
    type: String,
    required: true
  },
  notes: {
    type: String,
    trim: true
  }
});

const guestStudentSchema = new Schema<IGuestStudent>({
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  pickupStop: {
    type: String,
    required: true
  },
  dropoffStop: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: Object.values(StudentRideStatus),
    default: StudentRideStatus.PENDING
  },
  pickupTime: {
    type: Date
  },
  dropoffTime: {
    type: Date
  },
  notes: {
    type: String,
    trim: true
  }
});

const rideSchema = new Schema<IRide>({
  line: {
    type: Schema.Types.ObjectId,
    ref: 'Line',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: Object.values(RideStatus),
    default: RideStatus.SCHEDULED
  },
  startTime: {
    type: Date
  },
  endTime: {
    type: Date
  },
  students: [studentRideSchema],
  guests: [guestStudentSchema],
  driver: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  vehicle: {
    type: Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: true
  },
  notes: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
rideSchema.index({ line: 1, date: 1 });
rideSchema.index({ driver: 1, date: 1 });
rideSchema.index({ status: 1 });
rideSchema.index({ date: 1 });

// Virtual for total passengers
rideSchema.virtual('totalPassengers').get(function() {
  return this.students.length + this.guests.length;
});

// Virtual for available seats
rideSchema.virtual('availableSeats').get(function() {
  // This will be populated when we fetch the vehicle capacity
  return 0; // Placeholder, will be calculated in queries
});

// Ensure virtuals are serialized
rideSchema.set('toJSON', { virtuals: true });
rideSchema.set('toObject', { virtuals: true });

export default mongoose.model<IRide>('Ride', rideSchema); 