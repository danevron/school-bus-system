# School Bus System API

A comprehensive school ride management system that supports four user roles: Admin, Driver, Parent, and Student. The system manages transportation lines, routes, vehicles, and bookings for school transportation with advanced ride scheduling and real-time tracking capabilities.

## Features

### 🚌 Transportation Lines
- Create and manage transportation lines with schedules
- Assign drivers and vehicles to lines
- **NEW: Persistent student assignments to lines**
- Support for daily, weekday, weekend, and custom schedules
- Capacity management and tracking

### 🛣️ Routes & Stops
- Define routes with multiple pickup and dropoff stops
- Geographic coordinates for each stop
- Estimated travel times between stops
- Route optimization and management

### 🚗 Vehicle Management
- Fleet management with vehicle details
- Capacity tracking and maintenance scheduling
- License plate and vehicle information

### 📅 Booking System
- Parents can book rides for their children
- Real-time capacity checking
- Booking status tracking (pending, confirmed, cancelled, completed)
- Date-specific bookings

### 🚀 **NEW: Ride Management System**
- **Automatic ride generation** based on line schedules
- **Driver ride control** - start/end rides and track student pickup/dropoff
- **Parent ride management** - remove students from future rides
- **Guest student support** - admins can add temporary passengers
- **Real-time status tracking** for rides and individual students

### 👥 User Management
- Role-based access control (Admin, Driver, Parent, Student)
- Secure authentication with JWT tokens
- User profile management

## User Roles

### Admin
- Full system access
- Manage lines, routes, vehicles, and users
- **Assign students to lines for persistent transportation**
- **Generate rides automatically based on schedules**
- **Add guest students to specific rides**
- View all bookings and system reports
- Assign drivers and vehicles to lines

### Driver
- View assigned lines and schedules
- **Start and end rides**
- **Track individual student pickup and dropoff status**
- **Update ride progress in real-time**
- Access passenger lists for their routes

### Parent
- Book rides for their children
- View booking history and status
- **Remove children from future rides**
- Manage family accounts

### Student
- View assigned rides and schedules
- Access route information
- **Track ride status and pickup/dropoff times**

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile

### Lines
- `GET /api/lines` - Get all lines
- `POST /api/lines` - Create new line (Admin only)
- `GET /api/lines/:id` - Get line by ID
- `PUT /api/lines/:id` - Update line (Admin only)
- `DELETE /api/lines/:id` - Delete line (Admin only)
- `GET /api/lines/driver/my-lines` - Get driver's assigned lines
- **`POST /api/lines/:id/assign-students` - Assign students to line (Admin only)**
- **`POST /api/lines/:id/students` - Add student to line (Admin only)**
- **`DELETE /api/lines/:id/students/:studentId` - Remove student from line (Admin only)**

### **NEW: Rides**
- **`POST /api/rides/generate` - Generate rides for lines (Admin only)**
- **`GET /api/rides` - Get all rides (Admin only)**
- **`GET /api/rides/:id` - Get ride by ID**
- **`GET /api/rides/driver/my-rides` - Get driver's rides**
- **`PUT /api/rides/:id/status` - Update ride status (Admin/Driver)**
- **`PUT /api/rides/:rideId/students/:studentId/status` - Update student status (Driver)**
- **`POST /api/rides/:rideId/guests` - Add guest student (Admin only)**
- **`DELETE /api/rides/:rideId/students/:studentId` - Remove student from ride (Parent)**
- **`GET /api/rides/student/my-rides` - Get student's rides**

### Bookings
- `GET /api/bookings` - Get all bookings (Admin only)
- `POST /api/bookings` - Create booking (Parent only)
- `GET /api/bookings/:id` - Get booking by ID (Admin only)
- `PUT /api/bookings/:id` - Update booking (Admin only)
- `GET /api/bookings/parent/my-bookings` - Get parent's bookings
- `GET /api/bookings/line/:lineId` - Get bookings for specific line

### Routes
- `GET /api/routes` - Get all routes
- `POST /api/routes` - Create new route (Admin only)
- `GET /api/routes/:id` - Get route by ID
- `PUT /api/routes/:id` - Update route (Admin only)
- `DELETE /api/routes/:id` - Delete route (Admin only)

### Vehicles
- `GET /api/vehicles` - Get all vehicles
- `POST /api/vehicles` - Create new vehicle (Admin only)
- `GET /api/vehicles/:id` - Get vehicle by ID
- `PUT /api/vehicles/:id` - Update vehicle (Admin only)
- `DELETE /api/vehicles/:id` - Delete vehicle (Admin only)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd school-bus-system-backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the root directory:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/school-bus-system
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

4. Start MongoDB (make sure MongoDB is installed and running)

5. Seed the database with sample data:
```bash
npm run seed
```

6. Run the application:
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## Database Schema

### User
- `email` (unique)
- `password` (hashed)
- `firstName`, `lastName`
- `phone`
- `role` (admin, driver, parent, student)
- `isActive`

### Vehicle
- `licensePlate` (unique)
- `make`, `model`, `year`
- `capacity`
- `isActive`
- `lastMaintenance`

### Route
- `name`, `description`
- `stops` (array of stops with coordinates)
- `totalDistance`, `estimatedDuration`
- `isActive`

### Line
- `name`, `description`
- `route` (reference to Route)
- `driver` (reference to User)
- `vehicle` (reference to Vehicle)
- `schedule` (type, days, dates)
- `startTime`, `endTime`
- `maxCapacity`, `currentCapacity`
- **`students` (array of assigned students)**
- `isActive`

### **NEW: Ride**
- `line` (reference to Line)
- `date`
- `status` (scheduled, in_progress, completed, cancelled)
- `startTime`, `endTime`
- `students` (array with pickup/dropoff status)
- `guests` (array of guest students)
- `driver` (reference to User)
- `vehicle` (reference to Vehicle)
- `route` (reference to Route)
- `notes`

### Booking
- `student` (reference to User)
- `parent` (reference to User)
- `line` (reference to Line)
- `date`
- `pickupStop`, `dropoffStop`
- `status` (pending, confirmed, cancelled, completed)
- `notes`

## **NEW: Workflow**

### 1. Line Setup (Admin)
1. Create routes with stops
2. Create vehicles
3. Create lines with schedules
4. Assign students to lines
5. Generate rides automatically

### 2. Daily Operations (Driver)
1. View assigned rides for the day
2. Start ride when departing
3. Mark students as picked up at each stop
4. Mark students as dropped off at destination
5. End ride when complete

### 3. Parent Management
1. View child's assigned rides
2. Remove child from future rides if needed
3. Track ride progress in real-time

### 4. Guest Management (Admin)
1. Add guest students to specific rides
2. Ensure capacity limits are respected
3. Track guest information separately

## Security Features

- JWT-based authentication
- Password hashing with bcrypt
- Role-based access control
- Rate limiting
- CORS protection
- Helmet security headers
- Input validation with Joi

## Development

### Scripts
- `npm run dev` - Start development server with nodemon
- `npm start` - Start production server
- `npm run build` - Build TypeScript to JavaScript
- `npm test` - Run tests
- `npm run seed` - Seed database with sample data

### Environment Variables
- `PORT` - Server port (default: 3000)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `JWT_EXPIRES_IN` - JWT token expiration time
- `NODE_ENV` - Environment (development/production)
- `ALLOWED_ORIGINS` - Comma-separated list of allowed CORS origins

## API Response Format

All API responses follow a consistent format:

```json
{
  "message": "Success message",
  "data": {
    // Response data
  }
}
```

Error responses:
```json
{
  "message": "Error message",
  "error": "Detailed error information (development only)"
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the ISC License.
