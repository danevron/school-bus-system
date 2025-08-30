import mongoose from 'mongoose';
import User, { UserRole } from '../models/User';
import Vehicle from '../models/Vehicle';
import Route from '../models/Route';
import Line, { ScheduleType } from '../models/Line';
import { RideService } from '../services/rideService';
import { connectDB } from '../config/database';

const sampleData = {
  users: [
    {
      email: 'admin@schoolbus.com',
      password: 'admin123',
      firstName: 'Admin',
      lastName: 'User',
      phone: '+1234567890',
      role: UserRole.ADMIN
    },
    {
      email: 'driver1@schoolbus.com',
      password: 'driver123',
      firstName: 'John',
      lastName: 'Driver',
      phone: '+1234567891',
      role: UserRole.DRIVER
    },
    {
      email: 'driver2@schoolbus.com',
      password: 'driver123',
      firstName: 'Jane',
      lastName: 'Smith',
      phone: '+1234567892',
      role: UserRole.DRIVER
    },
    {
      email: 'parent1@schoolbus.com',
      password: 'parent123',
      firstName: 'Mike',
      lastName: 'Parent',
      phone: '+1234567893',
      role: UserRole.PARENT
    },
    {
      email: 'student1@schoolbus.com',
      password: 'student123',
      firstName: 'Alice',
      lastName: 'Student',
      phone: '+1234567894',
      role: UserRole.STUDENT
    },
    {
      email: 'student2@schoolbus.com',
      password: 'student123',
      firstName: 'Bob',
      lastName: 'Johnson',
      phone: '+1234567895',
      role: UserRole.STUDENT
    },
    {
      email: 'student3@schoolbus.com',
      password: 'student123',
      firstName: 'Charlie',
      lastName: 'Brown',
      phone: '+1234567896',
      role: UserRole.STUDENT
    }
  ],
  vehicles: [
    {
      licensePlate: 'ABC123',
      make: 'Ford',
      vehicleModel: 'Transit',
      year: 2022,
      capacity: 15
    },
    {
      licensePlate: 'XYZ789',
      make: 'Mercedes',
      vehicleModel: 'Sprinter',
      year: 2021,
      capacity: 12
    }
  ],
  routes: [
    {
      name: 'Downtown Route',
      stops: [
        {
          name: 'Central Station',
          address: '123 Main St, Downtown',
          coordinates: { latitude: 40.7128, longitude: -74.0060 },
          estimatedTime: 0,
          type: 'pickup'
        },
        {
          name: 'School Campus',
          address: '456 Education Ave, Downtown',
          coordinates: { latitude: 40.7130, longitude: -74.0062 },
          estimatedTime: 15,
          type: 'dropoff'
        }
      ],
      totalDistance: 5.2,
      estimatedDuration: 20
    },
    {
      name: 'Suburban Route',
      stops: [
        {
          name: 'Suburban Park',
          address: '789 Park Rd, Suburbia',
          coordinates: { latitude: 40.7140, longitude: -74.0070 },
          estimatedTime: 0,
          type: 'pickup'
        },
        {
          name: 'Mall Stop',
          address: '321 Shopping Blvd, Suburbia',
          coordinates: { latitude: 40.7145, longitude: -74.0075 },
          estimatedTime: 10,
          type: 'pickup'
        },
        {
          name: 'School Campus',
          address: '456 Education Ave, Downtown',
          coordinates: { latitude: 40.7130, longitude: -74.0062 },
          estimatedTime: 25,
          type: 'dropoff'
        }
      ],
      totalDistance: 8.5,
      estimatedDuration: 30
    }
  ]
};

export const seedDatabase = async () => {
  try {
    await connectDB();
    
    console.log('🌱 Starting database seeding...');

    // Clear existing data
    await User.deleteMany({});
    await Vehicle.deleteMany({});
    await Route.deleteMany({});
    await Line.deleteMany({});
    await mongoose.model('Ride').deleteMany({});

    console.log('🗑️  Cleared existing data');

    // Create users
    const createdUsers = await User.insertMany(sampleData.users);
    console.log(`👥 Created ${createdUsers.length} users`);

    // Create vehicles
    const createdVehicles = await Vehicle.insertMany(sampleData.vehicles);
    console.log(`🚗 Created ${createdVehicles.length} vehicles`);

    // Create routes
    const createdRoutes = await Route.insertMany(sampleData.routes);
    console.log(`🛣️  Created ${createdRoutes.length} routes`);

    // Get references to users
    const admin = createdUsers.find(u => u.role === UserRole.ADMIN);
    const driver1 = createdUsers.find(u => u.email === 'driver1@schoolbus.com');
    const driver2 = createdUsers.find(u => u.email === 'driver2@schoolbus.com');
    const student1 = createdUsers.find(u => u.email === 'student1@schoolbus.com');
    const student2 = createdUsers.find(u => u.email === 'student2@schoolbus.com');
    const student3 = createdUsers.find(u => u.email === 'student3@schoolbus.com');

    // Create sample lines with student assignments
    const lines = [
      {
        name: 'Morning Downtown Line',
        description: 'Daily morning pickup from downtown',
        route: createdRoutes[0]._id,
        driver: driver1?._id,
        vehicle: createdVehicles[0]._id,
        schedule: {
          type: ScheduleType.WEEKDAYS,
          daysOfWeek: [1, 2, 3, 4, 5], // Monday to Friday
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-12-31')
        },
        maxCapacity: createdVehicles[0].capacity,
        currentCapacity: 0,
        students: [student1?._id, student2?._id] // Assign students to this line
      },
      {
        name: 'Morning Suburban Line',
        description: 'Daily morning pickup from suburbs',
        route: createdRoutes[1]._id,
        driver: driver2?._id,
        vehicle: createdVehicles[1]._id,
        schedule: {
          type: ScheduleType.WEEKDAYS,
          daysOfWeek: [1, 2, 3, 4, 5], // Monday to Friday
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-12-31')
        },
        maxCapacity: createdVehicles[1].capacity,
        currentCapacity: 0,
        students: [student3?._id] // Assign student to this line
      }
    ];

    const createdLines = await Line.insertMany(lines);
    console.log(`🚌 Created ${createdLines.length} lines with student assignments`);

    // Generate rides for the next 30 days
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    console.log('🚀 Generating rides...');
    const generatedRides = await RideService.generateRidesForAllLines(startDate, endDate);
    console.log(`📅 Generated ${generatedRides.length} rides`);

    console.log('✅ Database seeding completed successfully!');
    console.log('\n📋 Sample Data Summary:');
    console.log(`- Users: ${createdUsers.length}`);
    console.log(`- Vehicles: ${createdVehicles.length}`);
    console.log(`- Routes: ${createdRoutes.length}`);
    console.log(`- Lines: ${createdLines.length}`);
    console.log(`- Rides: ${generatedRides.length}`);
    console.log('\n🔑 Sample Login Credentials:');
    console.log('Admin: admin@schoolbus.com / admin123');
    console.log('Driver: driver1@schoolbus.com / driver123');
    console.log('Parent: parent1@schoolbus.com / parent123');
    console.log('Student: student1@schoolbus.com / student123');
    console.log('\n📝 New Features Demo:');
    console.log('- Lines now have assigned students');
    console.log('- Rides are automatically generated based on line schedules');
    console.log('- Drivers can manage ride status and student pickup/dropoff');
    console.log('- Parents can remove students from future rides');
    console.log('- Admins can add guest students to rides');

    await mongoose.disconnect();
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
};

// Run seeder if called directly
if (require.main === module) {
  seedDatabase();
} 