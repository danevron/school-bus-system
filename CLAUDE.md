# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo Structure

This is a **monorepo** containing multiple applications for the School Bus System:

```
school-bus-system/                 # Monorepo root
├── backend/                      # Node.js + TypeScript REST API
├── frontend/                     # Vue.js admin interface  
├── mobile/                       # Flutter mobile app (planned)
├── shared/                       # Shared resources
│   ├── api-docs/                # OpenAPI spec & documentation
│   └── config/                  # Shared configurations
└── package.json                  # Monorepo orchestration
```

## Development Commands

### Monorepo Commands (run from root)
- `npm run dev` - Start both backend and frontend in development mode
- `npm run dev:backend` - Start backend development server only (nodemon + ts-node)
- `npm run dev:frontend` - Start frontend development server only (Vite, port 5173)
- `npm run build` - Build both backend and frontend
- `npm run test` - Run backend tests with Jest
- `npm run seed` - Seed database with sample data (uses seeder.ts utility)
- `npm run install:all` - Install dependencies for all workspaces
- `npm run clean:all` - Clean all node_modules and build artifacts

### Individual Project Commands
**Backend** (`backend/` directory):
- `npm run dev` - Start development server with nodemon
- `npm start` - Start production server (requires build first)
- `npm run build` - Build TypeScript to JavaScript (outputs to dist/)
- `npm test` - Run tests with Jest

**Frontend** (`frontend/` directory):
- `npm run dev` - Start Vue.js development server (port 5173)
- `npm run build` - Build frontend for production
- `npm run preview` - Preview production build

### Testing & Linting
- Use Jest for backend testing framework
- No specific lint or typecheck commands configured - suggest adding these if needed

## Architecture Overview

This is a **School Bus Ride Management System** built with:
- **Backend**: Node.js + TypeScript + Express for the REST API
- **Frontend**: Vue.js 3 + Vue Router SPA
- **Mobile**: Flutter app (planned for drivers and parents)
- **Database**: MongoDB + Mongoose for data persistence
- **Authentication**: JWT with role-based access control
- **4 User Roles**: Admin, Driver, Parent, Student

### Core Domain Models

**User System:**
- Users have roles (admin/driver/parent/student) with different permissions
- Authentication via JWT tokens with role-based middleware (`backend/src/middlewares/auth.ts`)

**Transportation Hierarchy:**
- **Routes** → Define pickup/dropoff stops with coordinates and timing
- **Vehicles** → Fleet management with capacity tracking  
- **Lines** → Scheduled transportation routes linking route + driver + vehicle + students
- **Rides** → Generated instances of line schedules with real-time tracking

**Key Business Flow:**
1. Admin creates Vehicles and Lines with embedded routes
2. Admin assigns Students to Lines with pickup/dropoff stops
3. Lines provide scheduled transportation services
4. Drivers manage assigned transportation lines
5. Parents can view children's transportation assignments

### Project Structure

**Backend** (`backend/src/`):
```
backend/src/
├── app.ts              # Express app configuration
├── server.ts           # Server startup and DB connection
├── config/database.ts  # MongoDB connection setup
├── models/             # Mongoose schemas (User, Line, Vehicle)
├── controllers/        # Route handlers for each domain
├── routes/            # Express route definitions
├── middlewares/auth.ts # JWT authentication & role authorization
├── services/          # Business logic
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

**Authentication** (`backend/src/middlewares/auth.ts`):
- Exports role-specific middleware: `requireAdmin`, `requireDriver`, `requireParent`, `requireStudent`
- JWT token verification and role-based access control

### Environment Configuration

Required `.env` variables (place in `backend/` directory):
- `PORT` (default: 3000)
- `MONGODB_URI` (default: mongodb://localhost:27017/school-bus-system)
- `JWT_SECRET` & `JWT_EXPIRES_IN`
- `NODE_ENV`
- `ALLOWED_ORIGINS` (comma-separated CORS origins, include http://localhost:5173 for frontend)

### API Design Patterns

- Consistent response format: `{ message: string, data?: any }`
- Role-based route protection with middleware composition
- Mongoose populate() for related data fetching
- Query filtering via URL parameters
- Comprehensive error handling with development/production modes