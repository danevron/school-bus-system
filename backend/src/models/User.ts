import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';

export enum UserRole {
  ADMIN = 'admin',
  DRIVER = 'driver',
  PARENT = 'parent',
  STUDENT = 'student'
}

export interface IUser extends Document {
  email?: string;
  password?: string;
  firstName: string;
  lastName: string;
  phone: string;
  role: UserRole;
  isActive: boolean;
  // Parent-Student relationships
  parents?: mongoose.Types.ObjectId[]; // For students - references to parent users (max 2)
  children?: mongoose.Types.ObjectId[]; // For parents - references to student users
  // Guest user fields
  isGuest: boolean; // True if this is a temporary guest user
  invitedBy?: mongoose.Types.ObjectId; // Reference to user who invited this guest
  createdAt: Date;
  updatedAt: Date;
  comparePassword(candidatePassword: string): Promise<boolean>;
}

const userSchema = new Schema<IUser>({
  email: {
    type: String,
    required: function(this: IUser) {
      return this.role !== UserRole.STUDENT;
    },
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: function(this: IUser) {
      return this.role !== UserRole.STUDENT;
    },
    minlength: 6
  },
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
    required: function(this: IUser) {
      return !this.isGuest; // Phone is optional for guest users
    },
    trim: true
  },
  role: {
    type: String,
    enum: Object.values(UserRole),
    required: function(this: IUser) {
      return !this.isGuest; // Role will be set in pre-save for guests
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Parent-Student relationships
  parents: [{
    type: Schema.Types.ObjectId,
    ref: 'User',
    validate: {
      validator: function(this: IUser, value: mongoose.Types.ObjectId[]) {
        const arr = Array.isArray(value) ? value : [];
        if (this.role === UserRole.STUDENT) {
          return arr.length <= 2;
        }
        return arr.length === 0;
      },
      message: 'Students can have maximum 2 parents, non-students cannot have parents'
    }
  }],
  children: [{
    type: Schema.Types.ObjectId,
    ref: 'User',
    validate: {
      validator: function(this: IUser, value: mongoose.Types.ObjectId[]) {
        const arr = Array.isArray(value) ? value : [];
        if (this.role === UserRole.PARENT) {
          return true; // parents can have any number of children
        }
        return arr.length === 0; // non-parents must have no children
      },
      message: 'Only parents can have children'
    }
  }],
  // Guest user fields
  isGuest: {
    type: Boolean,
    default: false
  },
  invitedBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: function(this: IUser) {
      return this.isGuest; // Required only for guest users
    }
  }
}, {
  timestamps: true
});

// Create unique index for email only for non-student users
userSchema.index(
  { email: 1 }, 
  { 
    unique: true,
    partialFilterExpression: { 
      role: { $ne: UserRole.STUDENT },
      email: { $exists: true, $ne: null }
    }
  }
);

// Pre-validation hook to set guest user defaults
userSchema.pre('validate', function(next) {
  // Set guest users to student role before validation
  if (this.isGuest) {
    this.role = UserRole.STUDENT;
    // Ensure phone has a default value if not provided
    if (!this.phone) {
      this.phone = '';
    }
  }
  next();
});

// Pre-save hook to handle students and password hashing
userSchema.pre('save', async function(next) {
  // Remove email field for students to avoid unique index conflicts
  if (this.role === UserRole.STUDENT) {
    this.email = undefined;
  }
  
  // Hash password before saving (only if password exists)
  if (this.password && this.isModified('password')) {
    try {
      const salt = await bcrypt.genSalt(10);
      this.password = await bcrypt.hash(this.password, salt);
    } catch (error) {
      return next(error as Error);
    }
  }
  
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword: string): Promise<boolean> {
  if (!this.password) return false;
  const result = await bcrypt.compare(candidatePassword, this.password);
  return result;
};

export default mongoose.model<IUser>('User', userSchema);