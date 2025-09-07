import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IStudentAssignment extends Document {
  student: Types.ObjectId;
  line: Types.ObjectId;
  pickupStop?: string; // stopId from line.route.stops
  dropoffStop?: string; // stopId from line.route.stops
  isActive: boolean;
  assignedAt: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const studentAssignmentSchema = new Schema<IStudentAssignment>({
  student: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  line: {
    type: Schema.Types.ObjectId,
    ref: 'Line',
    required: true
  },
  pickupStop: {
    type: String,
    required: false,
    // This references the stopId field in the line.route.stops array
  },
  dropoffStop: {
    type: String,
    required: false,
    // This references the stopId field in the line.route.stops array
  },
  isActive: {
    type: Boolean,
    default: true
  },
  assignedAt: {
    type: Date,
    default: Date.now
  },
  notes: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Ensure a student can only be assigned to a line once (only for active assignments)
studentAssignmentSchema.index(
  { student: 1, line: 1 }, 
  { 
    unique: true,
    partialFilterExpression: { isActive: true }
  }
);

// Index for efficient queries
studentAssignmentSchema.index({ line: 1, isActive: 1 });
studentAssignmentSchema.index({ student: 1, isActive: 1 });

// Virtual to get pickup stop details from line
studentAssignmentSchema.virtual('pickupStopDetails', {
  ref: 'Line',
  localField: 'line',
  foreignField: '_id',
  justOne: true,
  transform: function(doc: { route: { stops: any[]; }; }, ret: any) {
    if (!doc || !doc.route || !this.pickupStop) return null;
    return doc.route.stops.find(stop => stop.stopId === this.pickupStop);
  }
});

// Virtual to get dropoff stop details from line
studentAssignmentSchema.virtual('dropoffStopDetails', {
  ref: 'Line',
  localField: 'line',
  foreignField: '_id',
  justOne: true,
  transform: function(doc: { route: { stops: any[]; }; }, ret: any) {
    if (!doc || !doc.route || !this.dropoffStop) return null;
    return doc.route.stops.find(stop => stop.stopId === this.dropoffStop);
  }
});

// Ensure virtuals are serialized
studentAssignmentSchema.set('toJSON', { virtuals: true });
studentAssignmentSchema.set('toObject', { virtuals: true });

export default mongoose.model<IStudentAssignment>('StudentAssignment', studentAssignmentSchema);