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
    unique: true,
    sparse: true,
    lowercase: true,
    trim: true
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
    required: true,
    trim: true
  },
  role: {
    type: String,
    enum: Object.values(UserRole),
    required: true
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
  }]
}, {
  timestamps: true
});

// Hash password before saving (only if password exists)
userSchema.pre('save', async function(next) {
  if (!this.password || !this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error as Error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword: string): Promise<boolean> {
  if (!this.password) return false;
  const result = await bcrypt.compare(candidatePassword, this.password);
  return result;
};

export default mongoose.model<IUser>('User', userSchema);