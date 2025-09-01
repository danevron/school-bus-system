import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { log } from '../utils/logger';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/school-bus-system';

export const connectDB = async (): Promise<void> => {
  try {
    await mongoose.connect(MONGODB_URI);
    log.info('MongoDB connected successfully', { uri: MONGODB_URI });
  } catch (error) {
    log.error('MongoDB connection error', { 
      uri: MONGODB_URI, 
      error: error instanceof Error ? error.message : error 
    });
    process.exit(1);
  }
};

export const disconnectDB = async (): Promise<void> => {
  try {
    await mongoose.disconnect();
    log.info('MongoDB disconnected successfully');
  } catch (error) {
    log.error('MongoDB disconnection error', { 
      error: error instanceof Error ? error.message : error 
    });
  }
}; 