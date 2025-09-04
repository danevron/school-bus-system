import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/school-bus-system';

async function fixBookingIndex() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    if (!db) {
      throw new Error('Database connection not established');
    }
    const bookingsCollection = db.collection('bookings');

    // List current indexes
    console.log('Current indexes:');
    const indexes = await bookingsCollection.indexes();
    indexes.forEach(index => {
      console.log('- ', JSON.stringify(index, null, 2));
    });

    // Drop the problematic unique index
    try {
      await bookingsCollection.dropIndex('ride_1_passenger_1');
      console.log('Successfully dropped old ride_1_passenger_1 index');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.log('Index ride_1_passenger_1 may not exist or already dropped:', errorMessage);
    }

    // The new partial index will be created automatically when the model is loaded
    console.log('New partial index will be created automatically by Mongoose schema');
    
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    
  } catch (error) {
    console.error('Error fixing booking index:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  fixBookingIndex();
}

export { fixBookingIndex };