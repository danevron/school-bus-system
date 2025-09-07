# School Bus System API Documentation

## Base URL
```
http://localhost:3000/api
```

## Authentication

All protected endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### Authentication

#### Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1234567890",
  "role": "parent"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "parent"
  }
}
```

#### Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "parent"
  }
}
```

#### Get Profile
```http
GET /auth/profile
```

**Response:**
```json
{
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890",
    "role": "parent",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Lines

#### Get All Lines
```http
GET /lines?isActive=true&driver=507f1f77bcf86cd799439011
```

**Response:**
```json
{
  "lines": [
    {
      "id": "507f1f77bcf86cd799439011",
      "name": "Morning Downtown Line",
      "description": "Daily morning pickup from downtown",
      "route": {
        "id": "507f1f77bcf86cd799439012",
        "name": "Downtown Route",
        "description": "Route covering downtown area"
      },
      "driver": {
        "id": "507f1f77bcf86cd799439013",
        "firstName": "John",
        "lastName": "Driver",
        "email": "driver@example.com"
      },
      "vehicle": {
        "id": "507f1f77bcf86cd799439014",
        "licensePlate": "ABC123",
        "make": "Ford",
        "model": "Transit",
        "capacity": 15
      },
      "schedule": {
        "type": "weekdays",
        "daysOfWeek": [1, 2, 3, 4, 5],
        "startDate": "2024-01-01T00:00:00.000Z",
        "endDate": "2024-12-31T00:00:00.000Z"
      },
      "isActive": true,
      "maxCapacity": 15,
      "currentCapacity": 5,
      "availableCapacity": 10,
      "students": [
        {
          "id": "507f1f77bcf86cd799439015",
          "firstName": "Alice",
          "lastName": "Student",
          "email": "alice@example.com"
        }
      ]
    }
  ]
}
```

#### Create Line (Admin Only)
```http
POST /lines
```

**Request Body:**
```json
{
  "name": "New Line",
  "description": "New transportation line",
  "route": "507f1f77bcf86cd799439012",
  "driver": "507f1f77bcf86cd799439013",
  "vehicle": "507f1f77bcf86cd799439014",
  "schedule": {
    "type": "weekdays",
    "daysOfWeek": [1, 2, 3, 4, 5],
    "startDate": "2024-01-01T00:00:00.000Z",
    "endDate": "2024-12-31T00:00:00.000Z"
  }
}
```

#### Assign Students to Line (Admin Only)
```http
POST /lines/:id/assign-students
```

**Request Body:**
```json
{
  "students": [
    "507f1f77bcf86cd799439015",
    "507f1f77bcf86cd799439016"
  ]
}
```

#### Add Student to Line (Admin Only)
```http
POST /lines/:id/students
```

**Request Body:**
```json
{
  "studentId": "507f1f77bcf86cd799439015"
}
```

#### Remove Student from Line (Admin Only)
```http
DELETE /lines/:id/students/:studentId
```

#### Get Driver's Lines
```http
GET /lines/driver/my-lines
```

### Vehicles

#### Get All Vehicles
```http
GET /vehicles?isActive=true
```

**Response:**
```json
{
  "vehicles": [
    {
      "id": "507f1f77bcf86cd799439014",
      "licensePlate": "ABC123",
      "make": "Ford",
      "model": "Transit",
      "year": 2022,
      "capacity": 15,
      "isActive": true,
      "lastMaintenance": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### Create Vehicle (Admin Only)
```http
POST /vehicles
```

**Request Body:**
```json
{
  "licensePlate": "XYZ789",
  "make": "Mercedes",
  "model": "Sprinter",
  "year": 2021,
  "capacity": 12
}
```

## Key Features

### Line Management with Embedded Routes
- Lines contain embedded route information with stops
- Integrated stop and student management
- No separate route endpoints needed

### Student Assignment to Lines
- Admins can assign students to lines with specific pickup/dropoff stops
- Capacity management and tracking
- Student assignment validation

## Error Responses

### Validation Error
```json
{
  "message": "Validation error message"
}
```

### Authentication Error
```json
{
  "message": "Invalid or expired token"
}
```

### Authorization Error
```json
{
  "message": "Insufficient permissions"
}
```

### Not Found Error
```json
{
  "message": "Resource not found"
}
```

### Server Error
```json
{
  "message": "Something went wrong!",
  "error": "Detailed error information (development only)"
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Rate Limiting

The API implements rate limiting:
- 100 requests per 15 minutes per IP address
- Rate limit headers are included in responses

## CORS

The API supports CORS for the following origins:
- `http://localhost:3000`
- `http://localhost:3001`
- `http://localhost:5173`

Additional origins can be configured via the `ALLOWED_ORIGINS` environment variable. 