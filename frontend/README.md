# School Bus System Frontend

Vue.js 3 frontend for the School Bus Management System.

## Quick Start

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Open http://localhost:5173 in your browser

## Demo Accounts

The login page includes demo account buttons for testing:
- **Admin**: admin@example.com / password123
- **Driver**: driver@example.com / password123  
- **Parent**: parent@example.com / password123
- **Student**: student@example.com / password123

## Features

- **Authentication**: JWT-based login with role-based access
- **Responsive Design**: Works on desktop and mobile
- **Role-based Dashboards**: Different views for Admin, Driver, Parent, Student
- **API Integration**: Connects to backend at http://localhost:3000
- **Route Protection**: Automatic redirects based on auth state

## Architecture

- **Vue 3**: Composition API
- **Vue Router**: Client-side routing with guards
- **Axios**: HTTP client with interceptors
- **Reactive Store**: Simple auth state management
- **Vite**: Development server and build tool

## Backend Connection

The frontend connects to the backend API at `http://localhost:3000/api` via proxy configuration in `vite.config.js`.

Make sure the backend server is running before using the frontend.