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

### Rides

#### Generate Rides (Admin Only)
```http
POST /rides/generate
```

**Request Body:**
```json
{
  "startDate": "2024-01-01T00:00:00.000Z",
  "endDate": "2024-01-31T00:00:00.000Z",
  "lineId": "507f1f77bcf86cd799439011"
}
```

#### Get All Rides (Admin Only)
```http
GET /rides?status=scheduled&line=507f1f77bcf86cd799439011&date=2024-01-15&driver=507f1f77bcf86cd799439013
```

**Response:**
```json
{
  "rides": [
    {
      "id": "507f1f77bcf86cd799439020",
      "line": {
        "id": "507f1f77bcf86cd799439011",
        "name": "Morning Downtown Line",
        "description": "Daily morning pickup from downtown"
      },
      "date": "2024-01-15T00:00:00.000Z",
      "status": "scheduled",
      "startTime": null,
      "endTime": null,
      "driver": {
        "id": "507f1f77bcf86cd799439013",
        "firstName": "John",
        "lastName": "Driver"
      },
      "vehicle": {
        "id": "507f1f77bcf86cd799439014",
        "licensePlate": "ABC123",
        "make": "Ford",
        "model": "Transit",
        "capacity": 15
      },
      "students": [
        {
          "student": {
            "id": "507f1f77bcf86cd799439015",
            "firstName": "Alice",
            "lastName": "Student"
          },
          "status": "pending",
          "pickupTime": null,
          "dropoffTime": null,
          "pickupStop": "507f1f77bcf86cd799439016",
          "dropoffStop": "507f1f77bcf86cd799439017"
        }
      ],
      "guests": [],
      "totalPassengers": 1,
      "availableSeats": 14
    }
  ]
}
```

#### Get Ride by ID
```http
GET /rides/:id
```

#### Get Driver's Rides
```http
GET /rides/driver/my-rides?date=2024-01-15
```

#### Update Ride Status (Admin/Driver)
```http
PUT /rides/:id/status
```

**Request Body:**
```json
{
  "status": "in_progress"
}
```

**Available Statuses:**
- `scheduled` - Ride is scheduled but not started
- `in_progress` - Ride has started
- `completed` - Ride has finished
- `cancelled` - Ride has been cancelled

#### Update Student Status (Driver)
```http
PUT /rides/:rideId/students/:studentId/status
```

**Request Body:**
```json
{
  "status": "picked_up",
  "notes": "Student picked up at Central Station"
}
```

**Available Student Statuses:**
- `pending` - Student not yet picked up
- `picked_up` - Student has been picked up
- `dropped_off` - Student has been dropped off
- `absent` - Student was not present

#### Add Guest Student to Ride (Admin Only)
```http
POST /rides/:rideId/guests
```

**Request Body:**
```json
{
  "firstName": "Guest",
  "lastName": "Student",
  "phone": "+1234567890",
  "pickupStop": "507f1f77bcf86cd799439016",
  "dropoffStop": "507f1f77bcf86cd799439017",
  "notes": "Guest student for today only"
}
```

#### Remove Student from Ride (Parent)
```http
DELETE /rides/:rideId/students/:studentId
```

**Request Body:**
```json
{
  "reason": "Student is sick today"
}
```

#### Get Student's Rides
```http
GET /rides/student/my-rides?startDate=2024-01-01&endDate=2024-01-31
```

### Bookings

#### Create Booking (Parent Only)
```http
POST /bookings
```

**Request Body:**
```json
{
  "student": "507f1f77bcf86cd799439015",
  "line": "507f1f77bcf86cd799439011",
  "date": "2024-01-15T00:00:00.000Z",
  "pickupStop": "507f1f77bcf86cd799439016",
  "dropoffStop": "507f1f77bcf86cd799439017",
  "notes": "Please pick up at the main entrance"
}
```

**Response:**
```json
{
  "message": "Booking created successfully",
  "booking": {
    "id": "507f1f77bcf86cd799439018",
    "student": {
      "id": "507f1f77bcf86cd799439015",
      "firstName": "Alice",
      "lastName": "Student"
    },
    "line": {
      "id": "507f1f77bcf86cd799439011",
      "name": "Morning Downtown Line"
    },
    "date": "2024-01-15T00:00:00.000Z",
    "pickupStop": "507f1f77bcf86cd799439016",
    "dropoffStop": "507f1f77bcf86cd799439017",
    "status": "pending",
    "notes": "Please pick up at the main entrance",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

#### Get Parent's Bookings
```http
GET /bookings/parent/my-bookings
```

#### Get Bookings for Line
```http
GET /bookings/line/507f1f77bcf86cd799439011?date=2024-01-15
```

#### Update Booking (Admin Only)
```http
PUT /bookings/:id
```

**Request Body:**
```json
{
  "status": "confirmed",
  "notes": "Booking confirmed"
}
```

### Routes

#### Get All Routes
```http
GET /routes?isActive=true
```

**Response:**
```json
{
  "routes": [
    {
      "id": "507f1f77bcf86cd799439012",
      "name": "Downtown Route",
      "description": "Route covering downtown area",
      "stops": [
        {
          "name": "Central Station",
          "address": "123 Main St, Downtown",
          "coordinates": {
            "latitude": 40.7128,
            "longitude": -74.0060
          },
          "estimatedTime": 0,
          "type": "pickup"
        },
        {
          "name": "School Campus",
          "address": "456 Education Ave, Downtown",
          "coordinates": {
            "latitude": 40.7130,
            "longitude": -74.0062
          },
          "estimatedTime": 15,
          "type": "dropoff"
        }
      ],
      "totalDistance": 5.2,
      "estimatedDuration": 20,
      "isActive": true
    }
  ]
}
```

#### Create Route (Admin Only)
```http
POST /routes
```

**Request Body:**
```json
{
  "name": "New Route",
  "description": "New transportation route",
  "stops": [
    {
      "name": "Stop 1",
      "address": "123 Main St",
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "estimatedTime": 0,
      "type": "pickup"
    },
    {
      "name": "Stop 2",
      "address": "456 School St",
      "coordinates": {
        "latitude": 40.7130,
        "longitude": -74.0062
      },
      "estimatedTime": 15,
      "type": "dropoff"
    }
  ],
  "totalDistance": 5.2,
  "estimatedDuration": 20
}
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

## New Features

### Student Assignment to Lines
- Admins can assign students to lines for persistent transportation
- Students are automatically included in all rides for their assigned line
- Capacity checks prevent over-assignment

### Automatic Ride Generation
- Rides are automatically generated based on line schedules
- Supports daily, weekday, weekend, and custom schedules
- Each ride includes all assigned students

### Driver Ride Management
- Drivers can start and end rides
- Track individual student pickup and dropoff status
- Real-time status updates with timestamps

### Parent Controls
- Parents can remove their students from future rides
- Cannot modify past or current rides
- Provides reason for removal

### Guest Student Management
- Admins can add guest students to specific rides
- Capacity checks ensure available seats
- Guest information is tracked separately

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