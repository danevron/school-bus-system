import mongoose, { Document, Schema, Types } from 'mongoose';

export enum BookingStatus {
  UNCONFIRMED = 'unconfirmed',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
  CHECKED_IN = 'checked_in',  // Passenger is onboard
  COMPLETED = 'completed',    // Passenger has been dropped off
  WAITING_LIST = 'waiting_list' // Booking is on waiting list due to full capacity
}

export interface IBooking extends Document {
  // Core booking information
  ride: Types.ObjectId; // ref: Ride
  passenger: Types.ObjectId; // ref: User (any role)
  
  // Stop information
  pickupStop: {
    stopId: string;
    name: string;
    address: string;
    estimatedTime?: Date;
    actualPickupTime?: Date;
  };
  dropoffStop?: {
    stopId: string;
    name: string;
    address: string;
    estimatedTime?: Date;
    actualDropoffTime?: Date;
  };
  
  // Booking status and management
  status: BookingStatus;
  bookingDate: Date; // When the booking was made
  
  // Confirmation and cancellation
  confirmedAt?: Date;
  confirmedBy?: Types.ObjectId; // ref: User (admin who confirmed)
  cancelledAt?: Date;
  cancelledBy?: Types.ObjectId; // ref: User (who cancelled)
  cancellationReason?: string;
  
  // Check-in/out tracking (for driver use)
  checkedInAt?: Date;
  checkedInBy?: Types.ObjectId; // ref: User (driver)
  droppedOffAt?: Date;
  droppedOffBy?: Types.ObjectId; // ref: User (driver)
  
  // Metadata
  notes?: string;
  createdBy: Types.ObjectId; // ref: User (who created the booking)
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  confirm(confirmedBy: Types.ObjectId): Promise<IBooking>;
  cancel(cancelledBy: Types.ObjectId, reason?: string): Promise<IBooking>;
  checkIn(driverId: Types.ObjectId): Promise<IBooking>;
  dropOff(driverId: Types.ObjectId): Promise<IBooking>;
  admit(admittedBy: Types.ObjectId): Promise<IBooking>;
  canBeCancelled(): { canCancel: boolean; reason?: string };
}

const BookingSchema = new Schema<IBooking>({
  ride: {
    type: Schema.Types.ObjectId,
    ref: 'Ride',
    required: true
  },
  passenger: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  pickupStop: {
    stopId: {
      type: String,
      required: true
    },
    name: {
      type: String,
      required: true
    },
    address: {
      type: String,
      required: true
    },
    estimatedTime: {
      type: Date
    },
    actualPickupTime: {
      type: Date
    }
  },
  dropoffStop: {
    stopId: {
      type: String
    },
    name: {
      type: String
    },
    address: {
      type: String
    },
    estimatedTime: {
      type: Date
    },
    actualDropoffTime: {
      type: Date
    }
  },
  status: {
    type: String,
    enum: Object.values(BookingStatus),
    default: BookingStatus.UNCONFIRMED
  },
  bookingDate: {
    type: Date,
    default: Date.now
  },
  confirmedAt: {
    type: Date
  },
  confirmedBy: {
    type: Schema.Types.ObjectId,
    ref: 'User'
  },
  cancelledAt: {
    type: Date
  },
  cancelledBy: {
    type: Schema.Types.ObjectId,
    ref: 'User'
  },
  cancellationReason: {
    type: String
  },
  checkedInAt: {
    type: Date
  },
  checkedInBy: {
    type: Schema.Types.ObjectId,
    ref: 'User'
  },
  droppedOffAt: {
    type: Date
  },
  droppedOffBy: {
    type: Schema.Types.ObjectId,
    ref: 'User'
  },
  notes: {
    type: String
  },
  createdBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
BookingSchema.index({ ride: 1, status: 1 });
BookingSchema.index({ passenger: 1, status: 1 });
BookingSchema.index({ status: 1 });
// Prevent duplicate active bookings (allow new bookings after cancellation)
BookingSchema.index(
  { ride: 1, passenger: 1 }, 
  { 
    unique: true, 
    partialFilterExpression: { status: { $ne: BookingStatus.CANCELLED } } 
  }
);

// Validation: Pickup stop must be different from dropoff stop
BookingSchema.pre('validate', function(next) {
  if (this.dropoffStop && this.pickupStop.stopId === this.dropoffStop.stopId) {
    next(new Error('Pickup and dropoff stops cannot be the same'));
  } else {
    next();
  }
});

// Method to confirm booking
BookingSchema.methods.confirm = function(confirmedBy: Types.ObjectId) {
  this.status = BookingStatus.CONFIRMED;
  this.confirmedAt = new Date();
  this.confirmedBy = confirmedBy;
  return this.save();
};

// Method to cancel booking
BookingSchema.methods.cancel = function(cancelledBy: Types.ObjectId, reason?: string) {
  this.status = BookingStatus.CANCELLED;
  this.cancelledAt = new Date();
  this.cancelledBy = cancelledBy;
  this.cancellationReason = reason;
  return this.save();
};

// Method to check in passenger
BookingSchema.methods.checkIn = function(driverId: Types.ObjectId) {
  this.status = BookingStatus.CHECKED_IN;
  this.checkedInAt = new Date();
  this.checkedInBy = driverId;
  return this.save();
};

// Method to drop off passenger
BookingSchema.methods.dropOff = function(driverId: Types.ObjectId) {
  this.status = BookingStatus.COMPLETED;
  this.droppedOffAt = new Date();
  this.droppedOffBy = driverId;
  return this.save();
};

// Method to admit waiting list booking
BookingSchema.methods.admit = function(admittedBy: Types.ObjectId) {
  this.status = BookingStatus.UNCONFIRMED;
  return this.save();
};

// Method to check if booking can be cancelled
BookingSchema.methods.canBeCancelled = function() {
  if (this.status === BookingStatus.CANCELLED) {
    return { canCancel: false, reason: 'Booking is already cancelled' };
  }
  
  if (this.status === BookingStatus.CHECKED_IN) {
    return { canCancel: false, reason: 'Passenger is already onboard' };
  }
  
  if (this.status === BookingStatus.COMPLETED) {
    return { canCancel: false, reason: 'Ride has been completed' };
  }
  
  // You could add time-based restrictions here
  // e.g., cannot cancel within X hours of ride start
  
  return { canCancel: true };
};

// Post-save middleware to update ride available seats and handle waiting list
BookingSchema.post('save', async function(doc) {
  const Ride = mongoose.model('Ride');
  const ride = await Ride.findById(doc.ride);
  if (ride) {
    await ride.updateAvailableSeats();
    
    // If a booking was cancelled and there are now available seats, 
    // check if there are waiting list bookings to admit
    if (doc.status === BookingStatus.CANCELLED && ride.availableSeats > 0) {
      const Booking = mongoose.model('Booking');
      const waitingBooking = await Booking.findOne({
        ride: doc.ride,
        status: BookingStatus.WAITING_LIST
      }).sort({ createdAt: 1 }); // Get the oldest waiting booking
      
      if (waitingBooking) {
        await waitingBooking.admit(new Types.ObjectId());
      }
    }
  }
});

// Post-remove middleware to update ride available seats
BookingSchema.post('deleteOne', async function(doc) {
  const Ride = mongoose.model('Ride');
  const ride = await Ride.findById(doc.ride);
  if (ride) {
    await ride.updateAvailableSeats();
  }
});

export default mongoose.model<IBooking>('Booking', BookingSchema);