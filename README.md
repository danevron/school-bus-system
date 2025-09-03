# School Bus System

A comprehensive school transportation management system that supports four user roles: Admin, Driver, Parent, and Student. The system manages transportation lines with embedded routes, vehicles, and student assignments.

## Features

### 🚌 Transportation Lines
- Create and manage transportation lines with schedules
- Assign drivers and vehicles to lines
- **NEW: Persistent student assignments to lines**
- Support for daily, weekday, weekend, and custom schedules
- Capacity management and tracking

### 🛣️ Routes & Stops
- Routes are embedded within transportation lines
- Define stops with pickup and dropoff locations
- Geographic coordinates and timing for each stop
- Student assignment tracking per stop

### 🚗 Vehicle Management
- Fleet management with vehicle details
- Capacity tracking and maintenance scheduling
- License plate and vehicle information



### 👥 User Management
- Role-based access control (Admin, Driver, Parent, Student)
- Secure authentication with JWT tokens
- User profile management

## User Roles

### Admin
- Full system access
- Manage lines, vehicles, and users
- **Assign students to lines with pickup/dropoff stops**
- View system reports
- Assign drivers and vehicles to lines

### Driver
- View assigned lines and schedules
- Access passenger lists for their routes

### Parent
- Manage family accounts
- View children's transportation assignments

### Student
- View assigned transportation lines
- Access route information

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
- **`GET /api/lines/:id/student-assignments` - Get student assignments for line**
- **`POST /api/lines/:id/student-assignments` - Add student assignment to line (Admin only)**
- **`PUT /api/lines/:id/student-assignments/:assignmentId` - Update student assignment (Admin only)**
- **`DELETE /api/lines/:id/student-assignments/:assignmentId` - Remove student assignment (Admin only)**
- **`GET /api/lines/:id/stop-usage` - Get stop usage information**
- **`POST /api/lines/:id/route/stops` - Add stop to line route (Admin only)**
- **`PUT /api/lines/:id/route/stops` - Reorder route stops (Admin only)**
- **`DELETE /api/lines/:id/route/stops/:index` - Delete route stop (Admin only)**
- **`PUT /api/lines/:id/route` - Update route information (Admin only)**




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

## Frontend Architecture

The system includes a Vue.js frontend located in the `frontend/` directory:

### Key Components
- **LineView** - Display line details with embedded route information
- **LineRouteManager** - Comprehensive line management (stops + students)
- **RouteMap** - Reusable map component with Leaflet.js integration
- **StudentSelectionDialog** - Student assignment interface
- **StopCreationDialog** - Stop creation and editing

### Frontend Features
- **Integrated Route Management** - Routes are managed directly within lines
- **Interactive Maps** - Leaflet-based maps with driving directions
- **Student Assignment** - Visual interface for assigning students to stops
- **Real-time Updates** - Live capacity and usage tracking

### Development Commands
```bash
cd frontend
npm install
npm run dev  # Start development server on port 5173
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

### Line
- `name`, `description`
- **`route` (embedded route object with stops)**
  - `name`
  - `stops` (array of stops with coordinates, types, timing)
  - `totalDistance`, `estimatedDuration`
- `driver` (reference to User)
- `vehicle` (reference to Vehicle)
- `schedule` (type, days, dates)
- `maxCapacity`, `currentCapacity`
- `isActive`

### **NEW: StudentAssignment**
- `student` (reference to User)
- `line` (reference to Line)
- `pickupStop`, `dropoffStop` (stop IDs)
- `isActive`



## Workflow

### 1. Line Setup (Admin)
1. Create vehicles and assign drivers
2. Create lines with embedded route and stops
3. Configure schedules for lines
4. Assign students to lines with pickup/dropoff stops

### 2. Daily Operations (Driver)
1. View assigned lines and schedules
2. Access student lists for transportation

### 3. Parent Management
1. View children's transportation assignments
2. Manage family information

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
