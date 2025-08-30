import mongoose, { Document, Schema, Types } from 'mongoose';

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
  route: Types.ObjectId;
  driver: Types.ObjectId;
  vehicle: Types.ObjectId;
  schedule: ISchedule;
  isActive: boolean;
  maxCapacity: number;
  currentCapacity: number;
  students: Types.ObjectId[]; // Assigned students to this line
  createdAt: Date;
  updatedAt: Date;
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
    type: Schema.Types.ObjectId,
    ref: 'Route',
    required: true
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

export default mongoose.model<ILine>('Line', lineSchema); 