import mongoose, { Document, Schema } from 'mongoose';

export interface IVehicle {
  licensePlate: string;
  make: string;
  vehicleModel: string;
  year: number;
  capacity: number;
  isActive: boolean;
  lastMaintenance: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface IVehicleDocument extends IVehicle, Document {}

const vehicleSchema = new Schema<IVehicleDocument>({
  licensePlate: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    uppercase: true
  },
  make: {
    type: String,
    required: true,
    trim: true
  },
  vehicleModel: {
    type: String,
    required: true,
    trim: true
  },
  year: {
    type: Number,
    required: true,
    min: 1900,
    max: new Date().getFullYear() + 1
  },
  capacity: {
    type: Number,
    required: true,
    min: 1
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastMaintenance: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

export default mongoose.model<IVehicleDocument>('Vehicle', vehicleSchema); 