import Joi from 'joi';
import { UserRole } from '../models/User';
import { RideStatus, StudentRideStatus } from '../models/Ride';

export const userValidation = {
  register: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
    firstName: Joi.string().min(2).max(50).required(),
    lastName: Joi.string().min(2).max(50).required(),
    phone: Joi.string().pattern(/^\+?[\d\s\-\(\)]+$/).required(),
    role: Joi.string().valid(...Object.values(UserRole)).required()
  }),

  createStudent: Joi.object({
    firstName: Joi.string().min(2).max(50).required(),
    lastName: Joi.string().min(2).max(50).required(),
    phone: Joi.string().pattern(/^\+?[\d\s\-\(\)]+$/).required()
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),

  update: Joi.object({
    firstName: Joi.string().min(2).max(50),
    lastName: Joi.string().min(2).max(50),
    phone: Joi.string().pattern(/^\+?[\d\s\-\(\)]+$/),
    isActive: Joi.boolean()
  })
};

export const vehicleValidation = {
  create: Joi.object({
    licensePlate: Joi.string().required(),
    make: Joi.string().required(),
    vehicleModel: Joi.string().required(),
    year: Joi.number().integer().min(1900).max(new Date().getFullYear() + 1).required(),
    capacity: Joi.number().integer().min(1).required()
  }),

  update: Joi.object({
    make: Joi.string(),
    vehicleModel: Joi.string(),
    year: Joi.number().integer().min(1900).max(new Date().getFullYear() + 1),
    capacity: Joi.number().integer().min(1),
    isActive: Joi.boolean(),
    lastMaintenance: Joi.date()
  })
};

export const routeValidation = {
  create: Joi.object({
    name: Joi.string().required(),
    stops: Joi.array().items(
      Joi.object({
        name: Joi.string().required(),
        address: Joi.string().required(),
        coordinates: Joi.object({
          latitude: Joi.number().min(-90).max(90).required(),
          longitude: Joi.number().min(-180).max(180).required()
        }).required(),
        estimatedTime: Joi.number().min(0).required(),
        type: Joi.string().valid('pickup', 'dropoff').required()
      })
    ).min(0).required(),
    totalDistance: Joi.number().min(0).required(),
    estimatedDuration: Joi.number().min(0).required()
  })
};

export const lineValidation = {
  create: Joi.object({
    name: Joi.string().required(),
    description: Joi.string(),
    route: Joi.string().hex().length(24).required(),
    driver: Joi.string().hex().length(24).required(),
    vehicle: Joi.string().hex().length(24).required(),
    schedule: Joi.object({
      type: Joi.string().valid('daily', 'weekdays', 'weekends', 'custom').required(),
      daysOfWeek: Joi.array().items(Joi.number().min(0).max(6)),
      customDates: Joi.array().items(Joi.date()),
      startDate: Joi.date().required(),
      endDate: Joi.date()
    }).required(),
    startTime: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required(),
    endTime: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required(),
    maxCapacity: Joi.number().integer().min(1).required()
  }),

  assignStudents: Joi.object({
    students: Joi.array().items(Joi.string().hex().length(24)).required()
  })
};

export const bookingValidation = {
  create: Joi.object({
    student: Joi.string().hex().length(24).required(),
    line: Joi.string().hex().length(24).required(),
    date: Joi.date().min('now').required(),
    pickupStop: Joi.string().hex().length(24).required(),
    dropoffStop: Joi.string().hex().length(24).required(),
    notes: Joi.string()
  }),

  update: Joi.object({
    status: Joi.string().valid('pending', 'confirmed', 'cancelled', 'completed'),
    notes: Joi.string()
  })
};

export const rideValidation = {
  generateRides: Joi.object({
    startDate: Joi.date().required(),
    endDate: Joi.date().min(Joi.ref('startDate')).required()
  }),

  updateRideStatus: Joi.object({
    status: Joi.string().valid(...Object.values(RideStatus)).required()
  }),

  updateStudentStatus: Joi.object({
    studentId: Joi.string().hex().length(24).required(),
    status: Joi.string().valid(...Object.values(StudentRideStatus)).required(),
    notes: Joi.string()
  }),

  addGuestStudent: Joi.object({
    firstName: Joi.string().min(2).max(50).required(),
    lastName: Joi.string().min(2).max(50).required(),
    phone: Joi.string().pattern(/^\+?[\d\s\-\(\)]+$/).required(),
    pickupStop: Joi.string().hex().length(24).required(),
    dropoffStop: Joi.string().hex().length(24).required(),
    notes: Joi.string()
  }),

  removeStudent: Joi.object({
    studentId: Joi.string().hex().length(24).required(),
    reason: Joi.string()
  })
};

export const invitationValidation = {
  invite: Joi.object({
    email: Joi.string().email().required(),
    phone: Joi.string().pattern(/^\+?[\d\s\-\(\)]+$/).required(),
    role: Joi.string().valid(UserRole.PARENT, UserRole.DRIVER).required()
  }),

  accept: Joi.object({
    firstName: Joi.string().min(2).max(50).required(),
    lastName: Joi.string().min(2).max(50).required(),
    password: Joi.string().min(6).required()
  })
};

export const parentStudentValidation = {
  connectStudentToParents: Joi.object({
    studentId: Joi.string().hex().length(24).required(),
    parentIds: Joi.array().items(Joi.string().hex().length(24)).min(1).max(2).required()
  })
};

// Export individual validation functions for convenience
export const validateInviteUser = (data: any) => invitationValidation.invite.validate(data);
export const validateAcceptInvitation = (data: any) => invitationValidation.accept.validate(data);
export const validateConnectStudentToParents = (data: any) => parentStudentValidation.connectStudentToParents.validate(data); 