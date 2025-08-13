# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Development
- `npm run dev` - Start development server with nodemon (uses ts-node)
- `npm start` - Start production server (requires build first)
- `npm run build` - Build TypeScript to JavaScript (outputs to dist/)
- `npm test` - Run tests with Jest

### Database & Seeding
- `npm run seed` - Seed database with sample data (uses seeder.ts utility)

### Testing
- Use Jest for testing framework
- No specific lint or typecheck commands configured - suggest adding these if needed

### Frontend Development
- `cd frontend && npm run dev` - Start Vue.js frontend development server (port 5173)
- `cd frontend && npm run build` - Build frontend for production
- `cd frontend && npm run preview` - Preview production build

## Architecture Overview

This is a **School Bus Ride Management System** built with:
- **Backend**: Node.js + TypeScript + Express for the REST API
- **Frontend**: Vue.js 3 + Vue Router SPA
- **Database**: MongoDB + Mongoose for data persistence
- **Authentication**: JWT with role-based access control
- **4 User Roles**: Admin, Driver, Parent, Student

### Core Domain Models

**User System:**
- Users have roles (admin/driver/parent/student) with different permissions
- Authentication via JWT tokens with role-based middleware (`src/middlewares/auth.ts`)

**Transportation Hierarchy:**
- **Routes** → Define pickup/dropoff stops with coordinates and timing
- **Vehicles** → Fleet management with capacity tracking  
- **Lines** → Scheduled transportation routes linking route + driver + vehicle + students
- **Rides** → Generated instances of line schedules with real-time tracking

**Key Business Flow:**
1. Admin creates Routes, Vehicles, and Lines
2. Admin assigns Students to Lines permanently
3. System generates Rides automatically based on Line schedules
4. Drivers control ride status and track individual student pickup/dropoff
5. Parents can remove students from future rides

### Project Structure

**Backend** (`src/`):
```
src/
├── app.ts              # Express app configuration
├── server.ts           # Server startup and DB connection
├── config/database.ts  # MongoDB connection setup
├── models/             # Mongoose schemas (User, Line, Route, Vehicle, Ride, Booking)
├── controllers/        # Route handlers for each domain
├── routes/            # Express route definitions
├── middlewares/auth.ts # JWT authentication & role authorization
├── services/          # Business logic (RideService for scheduling)
└── utils/             # JWT helpers, validation, seeder
```

**Frontend** (`frontend/src/`):
```
frontend/src/
├── main.js           # Vue app entry point
├── App.vue           # Root Vue component
├── router.js         # Vue Router configuration
├── views/            # Page components (Login, Home)
├── components/       # Reusable Vue components
├── services/api.js   # Axios API service with interceptors
└── stores/auth.js    # Authentication state management
```

### Key Services

**RideService** (`src/services/rideService.ts`):
- Generates rides based on line schedules (daily, weekdays, weekends, custom)
- Handles driver ride queries and student ride lookups
- Manages capacity calculations

**Authentication** (`src/middlewares/auth.ts`):
- Exports role-specific middleware: `requireAdmin`, `requireDriver`, `requireParent`, `requireStudent`
- JWT token verification and role-based access control

### Environment Configuration

Required `.env` variables:
- `PORT` (default: 3000)
- `MONGODB_URI` (default: mongodb://localhost:27017/school-bus-system)
- `JWT_SECRET` & `JWT_EXPIRES_IN`
- `NODE_ENV`
- `ALLOWED_ORIGINS` (comma-separated CORS origins)

### API Design Patterns

- Consistent response format: `{ message: string, data?: any }`
- Role-based route protection with middleware composition
- Mongoose populate() for related data fetching
- Query filtering via URL parameters
- Comprehensive error handling with development/production modes