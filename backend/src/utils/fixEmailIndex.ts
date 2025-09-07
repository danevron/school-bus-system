import mongoose from 'mongoose';
import User, { UserRole } from '../models/User';

const fixEmailIndex = async () => {
  try {
    console.log('🔧 Fixing email index for users...');
    
    // Get the User collection
    const collection = User.collection;
    
    // Check existing indexes
    const indexes = await collection.indexes();
    console.log('Existing indexes:', indexes.map(idx => idx.name));
    
    // Drop the problematic email_1 index if it exists
    try {
      await collection.dropIndex('email_1');
      console.log('✅ Dropped old email_1 index');
    } catch (error) {
      console.log('ℹ️ email_1 index not found (already dropped or never existed)');
    }
    
    // Try to drop other email indexes that might exist
    try {
      const indexes = await collection.listIndexes().toArray();
      const emailIndexes = indexes.filter(idx => 
        idx.name && idx.name.includes('email') && idx.name !== 'email_unique_non_students'
      );
      
      for (const idx of emailIndexes) {
        try {
          await collection.dropIndex(idx.name!);
          console.log(`✅ Dropped index: ${idx.name}`);
        } catch (dropError) {
          console.log(`ℹ️ Could not drop index ${idx.name}`);
        }
      }
    } catch (error) {
      console.log('ℹ️ No additional email indexes to drop');
    }
    
    // Update existing student records to remove email field
    const studentsWithEmail = await User.find({ 
      role: UserRole.STUDENT, 
      email: { $exists: true } 
    });
    
    console.log(`Found ${studentsWithEmail.length} students with email field`);
    
    if (studentsWithEmail.length > 0) {
      await User.updateMany(
        { role: UserRole.STUDENT },
        { $unset: { email: "" } }
      );
      console.log('✅ Removed email field from all student records');
    }
    
    // Create the new partial index for non-student users
    try {
      await collection.createIndex(
        { email: 1 },
        {
          unique: true,
          partialFilterExpression: {
            role: { $in: ["admin", "driver", "parent"] },
            email: { $exists: true }
          },
          name: 'email_unique_non_students'
        }
      );
      console.log('✅ Created new partial unique index for non-student emails');
    } catch (indexError: any) {
      console.log('ℹ️ Partial index creation issue:', indexError.message);
    }
    
    // Verify the fix by checking indexes again
    const newIndexes = await collection.indexes();
    console.log('Updated indexes:', newIndexes.map(idx => ({ name: idx.name, key: idx.key })));
    
    console.log('🎉 Email index fix completed successfully!');
    
  } catch (error) {
    console.error('❌ Error fixing email index:', error);
    throw error;
  }
};

export default fixEmailIndex;

// Allow running this script directly
if (require.main === module) {
  const run = async () => {
    try {
      // Connect to database
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/school-bus-system';
      await mongoose.connect(mongoUri);
      console.log('Connected to MongoDB');
      
      await fixEmailIndex();
      
      await mongoose.disconnect();
      console.log('Disconnected from MongoDB');
      process.exit(0);
    } catch (error) {
      console.error('Script failed:', error);
      process.exit(1);
    }
  };
  
  run();
}