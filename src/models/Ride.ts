import mongoose, { Document, Schema, Types } from 'mongoose';

export enum RideStatus {
  SCHEDULED = 'scheduled',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

export interface IStop {
  stopId: string;
  name: string;
  address: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  estimatedArrivalTime?: Date;
  actualArrivalTime?: Date;
  type: 'pickup' | 'dropoff';
}

export interface IRide extends Document {
  // Basic ride information
  date: Date;
  startTime?: Date; // Optional scheduled start time
  actualStartTime?: Date; // When driver actually started
  actualEndTime?: Date; // When driver actually ended
  
  // Route information (independent, can be linked to line later)
  route: {
    name: string;
    stops: IStop[];
    estimatedDuration: number; // in minutes
    totalDistance: number; // in kilometers
  };
  
  // Assignment
  driver: Types.ObjectId; // ref: User (role: driver)
  vehicle: Types.ObjectId; // ref: Vehicle
  
  // Status and capacity
  status: RideStatus;
  maxCapacity: number; // from vehicle capacity
  availableSeats: number; // calculated field
  
  // Optional line reference (for future integration)
  lineId?: Types.ObjectId; // ref: Line (optional)
  
  // Metadata
  notes?: string;
  createdBy: Types.ObjectId; // ref: User (admin who created)
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  updateAvailableSeats(): Promise<void>;
  canBeBooked(): { canBook: boolean; reason?: string };
}

const StopSchema = new Schema<IStop>({
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
  coordinates: {
    latitude: {
      type: Number,
      required: true,
      min: -90,
      max: 90
    },
    longitude: {
      type: Number,
      required: true,
      min: -180,
      max: 180
    }
  },
  estimatedArrivalTime: {
    type: Date
  },
  actualArrivalTime: {
    type: Date
  },
  type: {
    type: String,
    enum: ['pickup', 'dropoff'],
    required: true
  }
}, { _id: false });

const RideSchema = new Schema<IRide>({
  date: {
    type: Date,
    required: true
  },
  startTime: {
    type: Date
  },
  actualStartTime: {
    type: Date
  },
  actualEndTime: {
    type: Date
  },
  route: {
    name: {
      type: String,
      required: true
    },
    stops: {
      type: [StopSchema],
      required: true,
      validate: {
        validator: function(stops: IStop[]) {
          return stops.length >= 2; // At least pickup and dropoff
        },
        message: 'Route must have at least 2 stops'
      }
    },
    estimatedDuration: {
      type: Number,
      required: true,
      min: 0
    },
    totalDistance: {
      type: Number,
      required: true,
      min: 0
    }
  },
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
  status: {
    type: String,
    enum: Object.values(RideStatus),
    default: RideStatus.SCHEDULED
  },
  maxCapacity: {
    type: Number,
    required: true,
    min: 1
  },
  availableSeats: {
    type: Number,
    required: true,
    min: 0
  },
  lineId: {
    type: Schema.Types.ObjectId,
    ref: 'Line'
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
RideSchema.index({ date: 1, status: 1 });
RideSchema.index({ driver: 1, date: 1 });
RideSchema.index({ status: 1 });
RideSchema.index({ lineId: 1 }); // for future line integration

// Virtual to get booking count
RideSchema.virtual('bookingCount', {
  ref: 'Booking',
  localField: '_id',
  foreignField: 'ride',
  count: true
});

// Method to update available seats
RideSchema.methods.updateAvailableSeats = async function() {
  const Booking = mongoose.model('Booking');
  const nonCancelledBookings = await Booking.countDocuments({
    ride: this._id,
    status: { $in: ['confirmed', 'checked_in', 'unconfirmed'] }
  });

  this.availableSeats = this.maxCapacity - nonCancelledBookings;
  return this.save();
};

// Method to check if ride can be booked
RideSchema.methods.canBeBooked = function() {
  if (this.status !== RideStatus.SCHEDULED) {
    return { canBook: false, reason: 'Ride is not available for booking' };
  }
  
  if (this.actualStartTime) {
    return { canBook: false, reason: 'Ride has already started' };
  }
  
  if (this.availableSeats <= 0) {
    return { canBook: false, reason: 'No available seats' };
  }
  
  return { canBook: true };
};

export default mongoose.model<IRide>('Ride', RideSchema);