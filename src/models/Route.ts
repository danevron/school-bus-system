import mongoose, { Document, Schema } from 'mongoose';

export interface IStop {
  name: string;
  address: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  estimatedTime: number; // minutes from start
  type: 'pickup' | 'dropoff';
}

export interface IRoute extends Document {
  name: string;
  stops: IStop[];
  totalDistance: number; // in kilometers
  estimatedDuration: number; // in minutes
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const stopSchema = new Schema<IStop>({
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
});

const routeSchema = new Schema<IRoute>({
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
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

export default mongoose.model<IRoute>('Route', routeSchema); 