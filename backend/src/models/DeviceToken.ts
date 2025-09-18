import mongoose, { Document, Schema } from 'mongoose';

export interface IDeviceToken extends Document {
  userId: mongoose.Types.ObjectId;
  fcmToken: string;
  deviceId?: string;
  platform: 'ios' | 'android';
  isActive: boolean;
  lastUsed: Date;
  createdAt: Date;
  updatedAt: Date;
}

const deviceTokenSchema = new Schema<IDeviceToken>({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  fcmToken: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  deviceId: {
    type: String,
    sparse: true
  },
  platform: {
    type: String,
    enum: ['ios', 'android'],
    required: true
  },
  isActive: {
    type: Boolean,
    default: true,
    index: true
  },
  lastUsed: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

deviceTokenSchema.index({ userId: 1, isActive: 1 });

deviceTokenSchema.index(
  { userId: 1, deviceId: 1 }, 
  { 
    unique: true,
    partialFilterExpression: { deviceId: { $exists: true, $ne: null } }
  }
);

export default mongoose.model<IDeviceToken>('DeviceToken', deviceTokenSchema);