import mongoose, { Document, Schema, Types } from 'mongoose';

export interface ILocationPoint {
  coordinates: {
    latitude: number;
    longitude: number;
  };
  timestamp: Date;
  speed?: number; // in km/h
  heading?: number; // in degrees (0-360)
  accuracy?: number; // in meters
}

export interface IRideProgress extends Document {
  rideId: Types.ObjectId; // ref: Ride
  driverId: Types.ObjectId; // ref: User (for verification)
  
  // Progress tracking
  startedAt: Date;
  endedAt?: Date;
  currentStatus: 'started' | 'in_progress' | 'completed';
  
  // Location tracking
  locationPoints: ILocationPoint[];
  
  // Current position info
  currentLocation?: {
    latitude: number;
    longitude: number;
  };
  lastUpdated: Date;
  
  // Stop tracking
  visitedStops?: {
    stopId: string;
    arrivedAt: Date;
    departedAt?: Date;
  }[];
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  addLocationPoint(point: ILocationPoint): Promise<void>;
  getCurrentProgress(): { 
    currentLocation: ILocationPoint | null; 
    totalDistance: number;
    isActive: boolean;
  };
}

const LocationPointSchema = new Schema<ILocationPoint>({
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
  timestamp: {
    type: Date,
    required: true,
    default: Date.now
  },
  speed: {
    type: Number,
    min: 0
  },
  heading: {
    type: Number,
    min: 0,
    max: 360
  },
  accuracy: {
    type: Number,
    min: 0
  }
}, { _id: false });

const VisitedStopSchema = new Schema({
  stopId: {
    type: String,
    required: true
  },
  arrivedAt: {
    type: Date,
    required: true
  },
  departedAt: {
    type: Date
  }
}, { _id: false });

const RideProgressSchema = new Schema<IRideProgress>({
  rideId: {
    type: Schema.Types.ObjectId,
    ref: 'Ride',
    required: true,
    unique: true // One progress record per ride
  },
  driverId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  startedAt: {
    type: Date,
    required: true,
    default: Date.now
  },
  endedAt: {
    type: Date
  },
  currentStatus: {
    type: String,
    enum: ['started', 'in_progress', 'completed'],
    default: 'started'
  },
  locationPoints: {
    type: [LocationPointSchema],
    default: []
  },
  currentLocation: {
    latitude: {
      type: Number,
      min: -90,
      max: 90
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180
    }
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  visitedStops: {
    type: [VisitedStopSchema],
    default: []
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
RideProgressSchema.index({ rideId: 1 });
RideProgressSchema.index({ driverId: 1 });
RideProgressSchema.index({ currentStatus: 1 });
RideProgressSchema.index({ startedAt: 1 });
RideProgressSchema.index({ lastUpdated: 1 });

// Method to add location point
RideProgressSchema.methods.addLocationPoint = async function(point: ILocationPoint) {
  this.locationPoints.push(point);
  this.currentLocation = point.coordinates;
  this.lastUpdated = point.timestamp;
  this.currentStatus = 'in_progress';
  
  // Keep only last 1000 points to prevent document size issues
  if (this.locationPoints.length > 1000) {
    this.locationPoints = this.locationPoints.slice(-1000);
  }
  
  return this.save();
};

// Method to get current progress
RideProgressSchema.methods.getCurrentProgress = function() {
  const lastLocation = this.locationPoints.length > 0 
    ? this.locationPoints[this.locationPoints.length - 1] 
    : null;
    
  // Calculate total distance traveled (simplified)
  let totalDistance = 0;
  for (let i = 1; i < this.locationPoints.length; i++) {
    const prev = this.locationPoints[i - 1];
    const curr = this.locationPoints[i];
    
    // Simple distance calculation (Haversine would be more accurate)
    const latDiff = curr.coordinates.latitude - prev.coordinates.latitude;
    const lonDiff = curr.coordinates.longitude - prev.coordinates.longitude;
    const distance = Math.sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111; // Rough km conversion
    totalDistance += distance;
  }
  
  return {
    currentLocation: lastLocation,
    totalDistance,
    isActive: this.currentStatus !== 'completed' && !this.endedAt
  };
};

export default mongoose.model<IRideProgress>('RideProgress', RideProgressSchema);