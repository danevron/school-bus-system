import { Request, Response } from 'express';
import Ride, { RideStatus } from '../models/Ride';
import Vehicle from '../models/Vehicle';
import User, { UserRole } from '../models/User';
import RideProgressService from '../services/rideProgressService';
import { rideValidation } from '../utils/validation';
import Booking from '../models/Booking';

export const rideController = {
  // Get all rides (Admin only)
  getAllRides: async (req: Request, res: Response) => {
    try {
      const { status, date, driverId } = req.query;
      
      const filter: any = {};
      
      if (status) {
        filter.status = status;
      }
      
      if (date) {
        const queryDate = new Date(date as string);
        filter.date = {
          $gte: new Date(queryDate.setHours(0, 0, 0, 0)),
          $lt: new Date(queryDate.setHours(23, 59, 59, 999))
        };
      }
      
      if (driverId) {
        filter.driver = driverId;
      }
      
      const rides = await Ride.find(filter)
        .populate('driver', 'firstName lastName phone email')
        .populate('vehicle', 'licensePlate make vehicleModel capacity')
        .populate('createdBy', 'firstName lastName')
        .populate('lineId', 'name description isActive')
        .sort({ date: 1, startTime: 1 });
      
      res.json({
        message: 'Rides retrieved successfully',
        data: { rides }
      });
    } catch (error) {
      console.error('Error getting rides:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve rides',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Get ride by ID
  getRideById: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      
      const ride = await Ride.findById(id)
        .populate('driver', 'firstName lastName phone email')
        .populate('vehicle', 'licensePlate make vehicleModel capacity')
        .populate('createdBy', 'firstName lastName')
        .populate('lineId', 'name description'); // for future line integration
      
      if (!ride) {
        return res.status(404).json({ message: 'Ride not found' });
      }
      
      res.json({
        message: 'Ride retrieved successfully',
        data: { ride }
      });
    } catch (error) {
      console.error('Error getting ride:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve ride',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Create new ride (Admin only)
  createRide: async (req: Request, res: Response) => {
    try {
      const { error } = rideValidation.create.validate(req.body);
      if (error) {
        return res.status(400).json({ message: error.details[0].message });
      }

      const {
        date,
        startTime,
        route,
        driver: driverId,
        vehicle: vehicleId,
        lineId,
        notes
      } = req.body;

      // Validate driver exists and has driver role
      const driver = await User.findById(driverId);
      if (!driver || driver.role !== UserRole.DRIVER) {
        return res.status(400).json({ message: 'Invalid driver specified' });
      }

      // Validate vehicle exists and is active
      const vehicle = await Vehicle.findById(vehicleId);
      if (!vehicle || !vehicle.isActive) {
        return res.status(400).json({ message: 'Invalid or inactive vehicle specified' });
      }

      // Check if driver is already assigned to another ride at the same date/time
      const existingRide = await Ride.findOne({
        driver: driverId,
        date: new Date(date),
        status: { $in: [RideStatus.SCHEDULED, RideStatus.IN_PROGRESS] }
      });

      if (existingRide) {
        return res.status(400).json({ 
          message: 'Driver is already assigned to another ride on this date' 
        });
      }

      // Check if vehicle is already assigned to another ride at the same date/time
      const existingVehicleRide = await Ride.findOne({
        vehicle: vehicleId,
        date: new Date(date),
        status: { $in: [RideStatus.SCHEDULED, RideStatus.IN_PROGRESS] }
      });

      if (existingVehicleRide) {
        return res.status(400).json({ 
          message: 'Vehicle is already assigned to another ride on this date' 
        });
      }

      const newRide = new Ride({
        date: new Date(date),
        startTime: startTime ? new Date(startTime) : undefined,
        route,
        driver: driverId,
        vehicle: vehicleId,
        maxCapacity: vehicle.capacity,
        availableSeats: vehicle.capacity, // Initially all seats are available
        lineId: lineId || undefined,
        notes,
        createdBy: req.user?.userId
      });

      const savedRide = await newRide.save();
      
      const populatedRide = await Ride.findById(savedRide._id)
        .populate('driver', 'firstName lastName phone email')
        .populate('vehicle', 'licensePlate make vehicleModel capacity')
        .populate('createdBy', 'firstName lastName');

      res.status(201).json({
        message: 'Ride created successfully',
        data: { ride: populatedRide }
      });
    } catch (error) {
      console.error('Error creating ride:', error);
      res.status(500).json({ 
        message: 'Failed to create ride',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Update ride (Admin only)
  updateRide: async (req: Request, res: Response) => {
    try {
      const { error } = rideValidation.update.validate(req.body);
      if (error) {
        return res.status(400).json({ message: error.details[0].message });
      }

      const { id } = req.params;
      const updates = req.body;

      const ride = await Ride.findById(id);
      if (!ride) {
        return res.status(404).json({ message: 'Ride not found' });
      }

      // Prevent updates to rides that have started or completed
      if (ride.status === RideStatus.IN_PROGRESS || ride.status === RideStatus.COMPLETED) {
        return res.status(400).json({ 
          message: 'Cannot update ride that is in progress or completed' 
        });
      }

      // If updating driver, validate the new driver
      if (updates.driver) {
        const driver = await User.findById(updates.driver);
        if (!driver || driver.role !== UserRole.DRIVER) {
          return res.status(400).json({ message: 'Invalid driver specified' });
        }
      }

      // If updating vehicle, validate the new vehicle and update capacity
      if (updates.vehicle) {
        const vehicle = await Vehicle.findById(updates.vehicle);
        if (!vehicle || !vehicle.isActive) {
          return res.status(400).json({ message: 'Invalid or inactive vehicle specified' });
        }
        updates.maxCapacity = vehicle.capacity;
        // Recalculate available seats
        await ride.updateAvailableSeats();
      }

      const updatedRide = await Ride.findByIdAndUpdate(id, updates, { 
        new: true, 
        runValidators: true 
      })
        .populate('driver', 'firstName lastName phone email')
        .populate('vehicle', 'licensePlate make vehicleModel capacity')
        .populate('createdBy', 'firstName lastName');

      res.json({
        message: 'Ride updated successfully',
        data: { ride: updatedRide }
      });
    } catch (error) {
      console.error('Error updating ride:', error);
      res.status(500).json({ 
        message: 'Failed to update ride',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Delete ride (Admin only)
  deleteRide: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;

      const ride = await Ride.findById(id);
      if (!ride) {
        return res.status(404).json({ message: 'Ride not found' });
      }

      // Prevent deletion of rides that have started
      if (ride.status === RideStatus.IN_PROGRESS || ride.status === RideStatus.COMPLETED) {
        return res.status(400).json({ 
          message: 'Cannot delete ride that is in progress or completed' 
        });
      }

      // Check if ride has any confirmed bookings
      const Booking = require('../models/Booking').default;
      const confirmedBookings = await Booking.countDocuments({
        ride: id,
        status: { $in: ['confirmed', 'checked_in'] }
      });

      if (confirmedBookings > 0) {
        return res.status(400).json({ 
          message: `Cannot delete ride with ${confirmedBookings} confirmed booking(s). Cancel bookings first.` 
        });
      }

      await Ride.findByIdAndDelete(id);

      res.json({ message: 'Ride deleted successfully' });
    } catch (error) {
      console.error('Error deleting ride:', error);
      res.status(500).json({ 
        message: 'Failed to delete ride',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Start ride (Driver only)
  startRide: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
      }

      const result = await RideProgressService.startRide(id, userId);

      res.json({
        message: 'Ride started successfully',
        data: result
      });
    } catch (error) {
      console.error('Error starting ride:', error);
      
      if (error instanceof Error) {
        if (error.message === 'Ride not found') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'User not found') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'Only assigned driver or admin can start this ride') {
          return res.status(403).json({ message: error.message });
        }
        if (error.message.includes('Cannot start ride') || 
            error.message === 'Ride has already been started' ||
            error.message === 'Ride progress already exists' ||
            error.message === 'Cannot start ride with no active bookings') {
          return res.status(400).json({ message: error.message });
        }
      }

      res.status(500).json({ 
        message: 'Failed to start ride',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // End ride (Driver only)
  endRide: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
      }

      const result = await RideProgressService.endRide(id, userId);

      // Mark all checked-in bookings as completed
      const Booking = require('../models/Booking').default;
      await Booking.updateMany(
        { 
          ride: id, 
          status: 'checked_in' 
        },
        { 
          status: 'completed',
          droppedOffAt: new Date(),
          droppedOffBy: userId
        }
      );

      res.json({
        message: 'Ride completed successfully',
        data: result
      });
    } catch (error) {
      console.error('Error ending ride:', error);
      
      if (error instanceof Error) {
        if (error.message === 'Ride not found') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'User not found') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'Only assigned driver or admin can end this ride') {
          return res.status(403).json({ message: error.message });
        }
        if (error.message.includes('Cannot end ride') || 
            error.message === 'Ride progress not found') {
          return res.status(400).json({ message: error.message });
        }
      }

      res.status(500).json({ 
        message: 'Failed to end ride',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Update ride location (Driver only)
  updateLocation: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
      }

      const { latitude, longitude, speed, heading, accuracy } = req.body;

      if (!latitude || !longitude) {
        return res.status(400).json({ message: 'Latitude and longitude are required' });
      }

      const result = await RideProgressService.updateLocation(id, userId, {
        latitude,
        longitude,
        speed,
        heading,
        accuracy
      });

      res.json({
        message: 'Location updated successfully',
        data: result
      });
    } catch (error) {
      console.error('Error updating location:', error);
      
      if (error instanceof Error) {
        if (error.message === 'Ride progress not found. Ride must be started first.') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'Only assigned driver can update location') {
          return res.status(403).json({ message: error.message });
        }
        if (error.message === 'Cannot update location for completed ride') {
          return res.status(400).json({ message: error.message });
        }
      }

      res.status(500).json({ 
        message: 'Failed to update location',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Get ride progress data
  getRideProgress: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { from } = req.query;
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
      }

      // Parse from timestamp if provided
      let fromTimestamp: Date | undefined;
      if (from) {
        fromTimestamp = new Date(from as string);
        if (isNaN(fromTimestamp.getTime())) {
          return res.status(400).json({ message: 'Invalid from timestamp format' });
        }
      }

      const result = await RideProgressService.getRideProgress(id, userId, fromTimestamp);

      res.json({
        message: 'Ride progress retrieved successfully',
        data: result
      });
    } catch (error) {
      console.error('Error getting ride progress:', error);
      
      if (error instanceof Error) {
        if (error.message === 'Ride not found' || error.message === 'Ride progress not found') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'User not found') {
          return res.status(404).json({ message: error.message });
        }
        if (error.message === 'Access denied to ride progress') {
          return res.status(403).json({ message: error.message });
        }
      }

      res.status(500).json({ 
        message: 'Failed to retrieve ride progress',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Get user's rides
  getUserRides: async (req: Request, res: Response) => {
    try {
    
      const user = req.user;
      const { status, date, fromDate } = req.query;
      const filter: any = {};

      if (user?.role === UserRole.DRIVER) {
        filter.driver = user.userId;
      } else {
        const passengerIds = [user?.userId];
        const userFromDb = await User.findById(user?.userId);
        if (userFromDb?.children) {
          // Include rides for children of parent users
          userFromDb.children.map(child => passengerIds.push(child._id.toString()));
        }
        
        // Find rides that have bookings for this user or their children
        const bookingFilter: any = {
          passenger: { $in: passengerIds },
          status: { $nin: ['cancelled'] }
        };

        filter._id = {
          $in: await Booking.find(bookingFilter).distinct('ride')
        };
      }

      if (status) {
        filter.status = status;
      }
      
      if (date) {
        const queryDate = new Date(date as string);
        filter.date = {
          $gte: new Date(queryDate.setHours(0, 0, 0, 0)),
          $lt: new Date(queryDate.setHours(23, 59, 59, 999))
        };
      } else if (fromDate) {
        const queryFromDate = new Date(fromDate as string);
        filter.date = {
          $gte: new Date(queryFromDate.setHours(0, 0, 0, 0))
        };
      }

      const rides = await Ride.find(filter)
        .populate('vehicle', 'licensePlate make vehicleModel capacity')
        .sort({ date: 1, startTime: 1 });

      res.json({
        message: 'Rides retrieved successfully',
        data: { rides }
      });
    } catch (error) {
      console.error('Error getting rides:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve rides',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  }
};