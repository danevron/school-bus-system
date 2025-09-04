import mongoose, { Document, Schema, Types } from 'mongoose';

// Route-related interfaces (moved from Route.ts)
export interface IStop {
  stopId: string; // Unique identifier for the stop
  name: string;
  address: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  estimatedTime: number; // minutes from start
  type: 'pickup' | 'dropoff';
}

export interface IRouteData {
  name: string;
  stops: IStop[];
  totalDistance: number; // in kilometers
  estimatedDuration: number; // in minutes
}

export enum ScheduleType {
  DAILY = 'daily',
  WEEKDAYS = 'weekdays',
  WEEKENDS = 'weekends',
  CUSTOM = 'custom'
}

export interface ISchedule {
  type: ScheduleType;
  daysOfWeek?: number[]; // 0-6 (Sunday-Saturday)
  customDates?: Date[];
  startDate: Date;
  endDate?: Date;
}

export interface ILine extends Document {
  name: string;
  description: string;
  route?: IRouteData; // Embedded route data (optional)
  driver: Types.ObjectId;
  vehicle: Types.ObjectId;
  schedule: ISchedule;
  isActive: boolean;
  maxCapacity: number;
  currentCapacity: number;
  students: Types.ObjectId[]; // Assigned students to this line
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  canBeActivated(): { canActivate: boolean; reason?: string };
  activate(): Promise<ILine>;
}

const scheduleSchema = new Schema<ISchedule>({
  type: {
    type: String,
    enum: Object.values(ScheduleType),
    required: true
  },
  daysOfWeek: [{
    type: Number,
    min: 0,
    max: 6
  }],
  customDates: [{
    type: Date
  }],
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date
  }
});

// Stop schema (moved from Route.ts)
const stopSchema = new Schema<IStop>({
  stopId: {
    type: String,
    required: true,
    unique: false // Not globally unique, just within the route
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  address: {
    type: String,
    required: true,
    trim: true
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
  estimatedTime: {
    type: Number,
    required: true,
    min: 0
  },
  type: {
    type: String,
    enum: ['pickup', 'dropoff'],
    required: true
  }
}, { _id: false }); // Disable automatic _id generation

// Route data schema (embedded in Line)
const routeDataSchema = new Schema<IRouteData>({
  name: {
    type: String,
    required: true,
    trim: true
  },
  stops: [stopSchema],
  totalDistance: {
    type: Number,
    required: true,
    min: 0
  },
  estimatedDuration: {
    type: Number,
    required: true,
    min: 0
  }
});

const lineSchema = new Schema<ILine>({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  route: {
    type: routeDataSchema,
    required: false
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
  schedule: {
    type: scheduleSchema,
    required: true
  },
  isActive: {
    type: Boolean,
    default: false
  },
  maxCapacity: {
    type: Number,
    required: true,
    min: 1
  },
  currentCapacity: {
    type: Number,
    default: 0,
    min: 0
  },
  students: [{
    type: Schema.Types.ObjectId,
    ref: 'User'
  }]
}, {
  timestamps: true
});

// Virtual for available capacity
lineSchema.virtual('availableCapacity').get(function() {
  return this.maxCapacity - this.currentCapacity;
});

// Ensure virtuals are serialized
lineSchema.set('toJSON', { virtuals: true });
lineSchema.set('toObject', { virtuals: true });

// Method to check if line can be activated
lineSchema.methods.canBeActivated = function() {
  if (this.isActive) {
    return { canActivate: false, reason: 'Line is already active' };
  }
  
  // Check if line has a route with stops
  if (!this.route || !this.route.stops || this.route.stops.length === 0) {
    return { canActivate: false, reason: 'Line must have a route with stops' };
  }
  
  // Check if line has at least one assigned student
  if (!this.students || this.students.length === 0) {
    return { canActivate: false, reason: 'Line must have at least one assigned student' };
  }
  
  return { canActivate: true };
};

// Method to activate line
lineSchema.methods.activate = async function() {
  const validation = this.canBeActivated();
  if (!validation.canActivate) {
    throw new Error(validation.reason);
  }
  
  this.isActive = true;
  return await this.save();
};

export default mongoose.model<ILine>('Line', lineSchema); 