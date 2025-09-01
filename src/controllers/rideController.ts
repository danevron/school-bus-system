import { Request, Response } from 'express';
import Ride, { RideStatus, StudentRideStatus } from '../models/Ride';
import Line from '../models/Line';
import User from '../models/User';
import { RideService } from '../services/rideService';
import { rideValidation } from '../utils/validation';
import { UserRole } from '../models/User';

export const generateRides = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = rideValidation.generateRides.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { startDate, endDate, lineId } = req.body;

    let rides;
    if (lineId) {
      rides = await RideService.generateRidesForLine(lineId, new Date(startDate), new Date(endDate));
    } else {
      rides = await RideService.generateRidesForAllLines(new Date(startDate), new Date(endDate));
    }

    res.status(201).json({
      message: 'Rides generated successfully',
      count: rides.length,
      rides
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getAllRides = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, line, date, driver } = req.query;
    const filter: any = {};

    if (status) {
      filter.status = status;
    }

    if (line) {
      filter.line = line;
    }

    if (date) {
      filter.date = {
        $gte: new Date(date as string),
        $lt: new Date(new Date(date as string).getTime() + 24 * 60 * 60 * 1000)
      };
    }

    if (driver) {
      filter.driver = driver;
    }

    const rides = await Ride.find(filter)
      .populate('line', 'name description route')
      .populate('driver', 'firstName lastName')
      .populate('vehicle', 'licensePlate make vehicleModel capacity')
      .populate('students.student', 'firstName lastName')
      .sort({ date: 1 });

    res.json({ rides });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getRideById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const ride = await Ride.findById(id)
      .populate('line', 'name description route')
      .populate('driver', 'firstName lastName phone')
      .populate('vehicle', 'licensePlate make vehicleModel capacity')
      .populate('students.student', 'firstName lastName phone');

    if (!ride) {
      res.status(404).json({ message: 'Ride not found' });
      return;
    }

    // Calculate available seats
    const availableSeats = await RideService.getAvailableSeats(id);

    res.json({ 
      ride: {
        ...ride.toObject(),
        availableSeats
      }
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getDriverRides = async (req: Request, res: Response): Promise<void> => {
  try {
    const driverId = req.user?.userId;
    const { date } = req.query;

    const rides = await RideService.getDriverRides(
      driverId!,
      date ? new Date(date as string) : undefined
    );

    res.json({ rides });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const updateRideStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { error } = rideValidation.updateRideStatus.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { status } = req.body;
    const updateData: any = { status };

    // Set start/end times based on status
    if (status === RideStatus.IN_PROGRESS) {
      updateData.startTime = new Date();
    } else if (status === RideStatus.COMPLETED) {
      updateData.endTime = new Date();
    }

    const ride = await Ride.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).populate([
      { path: 'line', select: 'name description' },
      { path: 'driver', select: 'firstName lastName' },
      { path: 'students.student', select: 'firstName lastName' }
    ]);

    if (!ride) {
      res.status(404).json({ message: 'Ride not found' });
      return;
    }

    res.json({
      message: 'Ride status updated successfully',
      ride
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const updateStudentStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { rideId, studentId } = req.params;
    const { error } = rideValidation.updateStudentStatus.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { status, notes } = req.body;
    const updateData: any = { status };

    // Set pickup/dropoff times based on status
    if (status === StudentRideStatus.PICKED_UP) {
      updateData.pickupTime = new Date();
    } else if (status === StudentRideStatus.DROPPED_OFF) {
      updateData.dropoffTime = new Date();
    }

    if (notes) {
      updateData.notes = notes;
    }

    const ride = await Ride.findOneAndUpdate(
      { 
        _id: rideId,
        'students.student': studentId 
      },
      {
        $set: {
          'students.$.status': updateData.status,
          'students.$.pickupTime': updateData.pickupTime,
          'students.$.dropoffTime': updateData.dropoffTime,
          'students.$.notes': updateData.notes
        }
      },
      { new: true, runValidators: true }
    ).populate([
      { path: 'students.student', select: 'firstName lastName' }
    ]);

    if (!ride) {
      res.status(404).json({ message: 'Ride or student not found' });
      return;
    }

    res.json({
      message: 'Student status updated successfully',
      ride
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const addGuestStudent = async (req: Request, res: Response): Promise<void> => {
  try {
    const { rideId } = req.params;
    const { error } = rideValidation.addGuestStudent.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    // Check available seats
    const availableSeats = await RideService.getAvailableSeats(rideId);
    if (availableSeats <= 0) {
      res.status(400).json({ message: 'No available seats on this ride' });
      return;
    }

    const guestData = {
      ...req.body,
      status: StudentRideStatus.PENDING
    };

    const ride = await Ride.findByIdAndUpdate(
      rideId,
      {
        $push: { guests: guestData }
      },
      { new: true, runValidators: true }
    ).populate([
      { path: 'guests', select: 'firstName lastName phone status' }
    ]);

    if (!ride) {
      res.status(404).json({ message: 'Ride not found' });
      return;
    }

    res.json({
      message: 'Guest student added successfully',
      ride
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const removeStudentFromRide = async (req: Request, res: Response): Promise<void> => {
  try {
    const { rideId, studentId } = req.params;
    const { error } = rideValidation.removeStudent.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { reason } = req.body;

    // Check if ride is in the future
    const ride = await Ride.findById(rideId);
    if (!ride) {
      res.status(404).json({ message: 'Ride not found' });
      return;
    }

    if (ride.date <= new Date()) {
      res.status(400).json({ message: 'Cannot remove student from past or current rides' });
      return;
    }

    // Remove student from ride
    const updatedRide = await Ride.findByIdAndUpdate(
      rideId,
      {
        $pull: { students: { student: studentId } }
      },
      { new: true, runValidators: true }
    ).populate([
      { path: 'students.student', select: 'firstName lastName' }
    ]);

    res.json({
      message: 'Student removed from ride successfully',
      ride: updatedRide
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getStudentRides = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.user?.userId;
    const { startDate, endDate } = req.query;

    const rides = await RideService.getStudentRides(
      studentId!,
      startDate ? new Date(startDate as string) : undefined,
      endDate ? new Date(endDate as string) : undefined
    );

    res.json({ rides });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
}; 