import Joi from 'joi';
import { UserRole } from '../models/User';

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


export const lineValidation = {
  create: Joi.object({
    name: Joi.string().required(),
    description: Joi.string(),
    route: Joi.object({
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
    }),
    driver: Joi.string().hex().length(24).required(),
    vehicle: Joi.string().hex().length(24).required(),
    schedule: Joi.object({
      type: Joi.string().valid('daily', 'weekdays', 'weekends', 'custom').required(),
      daysOfWeek: Joi.array().items(Joi.number().min(0).max(6)),
      customDates: Joi.array().items(Joi.date()),
      startDate: Joi.date().required(),
      endDate: Joi.date()
    }).required()
  }),

  updateRoute: Joi.object({
    name: Joi.string().required(),
    stops: Joi.array().items(
      Joi.object({
        stopId: Joi.string().optional(), // Optional for backwards compatibility
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
  }),

  assignStudents: Joi.object({
    students: Joi.array().items(Joi.string().hex().length(24)).required()
  }),

  // Stop management validations
  addStop: Joi.object({
    stop: Joi.object({
      name: Joi.string().required(),
      address: Joi.string().required(),
      coordinates: Joi.object({
        latitude: Joi.number().min(-90).max(90).required(),
        longitude: Joi.number().min(-180).max(180).required()
      }).required(),
      estimatedTime: Joi.number().min(0).required(),
      type: Joi.string().valid('pickup', 'dropoff').required()
    }).required()
  }),

  updateStops: Joi.object({
    stops: Joi.array().items(
      Joi.object({
        stopId: Joi.string().optional(), // Optional for backwards compatibility
        name: Joi.string().required(),
        address: Joi.string().required(),
        coordinates: Joi.object({
          latitude: Joi.number().min(-90).max(90).required(),
          longitude: Joi.number().min(-180).max(180).required()
        }).required(),
        estimatedTime: Joi.number().min(0).required(),
        type: Joi.string().valid('pickup', 'dropoff').required()
      })
    ).required()
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

export const rideValidation = {
  create: Joi.object({
    date: Joi.date().min('now').required(),
    startTime: Joi.date().optional(),
    route: Joi.object({
      name: Joi.string().required(),
      stops: Joi.array().items(
        Joi.object({
          stopId: Joi.string().required(),
          name: Joi.string().required(),
          address: Joi.string().required(),
          coordinates: Joi.object({
            latitude: Joi.number().min(-90).max(90).required(),
            longitude: Joi.number().min(-180).max(180).required()
          }).required(),
          estimatedArrivalTime: Joi.date().optional(),
          actualArrivalTime: Joi.date().optional(),
          type: Joi.string().valid('pickup', 'dropoff').required()
        })
      ).min(2).required(),
      estimatedDuration: Joi.number().min(0).required(),
      totalDistance: Joi.number().min(0).required()
    }).required(),
    driver: Joi.string().hex().length(24).required(),
    vehicle: Joi.string().hex().length(24).required(),
    lineId: Joi.string().hex().length(24).optional(),
    notes: Joi.string().optional()
  }),

  update: Joi.object({
    date: Joi.date().min('now').optional(),
    startTime: Joi.date().optional(),
    route: Joi.object({
      name: Joi.string().required(),
      stops: Joi.array().items(
        Joi.object({
          stopId: Joi.string().required(),
          name: Joi.string().required(),
          address: Joi.string().required(),
          coordinates: Joi.object({
            latitude: Joi.number().min(-90).max(90).required(),
            longitude: Joi.number().min(-180).max(180).required()
          }).required(),
          estimatedArrivalTime: Joi.date().optional(),
          actualArrivalTime: Joi.date().optional(),
          type: Joi.string().valid('pickup', 'dropoff').required()
        })
      ).min(2).required(),
      estimatedDuration: Joi.number().min(0).required(),
      totalDistance: Joi.number().min(0).required()
    }).optional(),
    driver: Joi.string().hex().length(24).optional(),
    vehicle: Joi.string().hex().length(24).optional(),
    lineId: Joi.string().hex().length(24).optional(),
    notes: Joi.string().optional(),
    status: Joi.string().valid('scheduled', 'in_progress', 'completed', 'cancelled').optional()
  })
};

export const bookingValidation = {
  create: Joi.object({
    rideId: Joi.string().hex().length(24).required(),
    passengerId: Joi.string().hex().length(24).required(),
    pickupStop: Joi.object({
      stopId: Joi.string().required(),
      name: Joi.string().optional(),
      address: Joi.string().optional(),
      estimatedTime: Joi.date().optional()
    }).required(),
    dropoffStop: Joi.object({
      stopId: Joi.string().required(),
      name: Joi.string().optional(),
      address: Joi.string().optional(),
      estimatedTime: Joi.date().optional()
    }).optional(),
    notes: Joi.string().optional()
  }),

  cancel: Joi.object({
    reason: Joi.string().optional()
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