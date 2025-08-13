import { Request, Response } from 'express';
import Booking, { BookingStatus } from '../models/Booking';
import Line from '../models/Line';
import User from '../models/User';
import { bookingValidation } from '../utils/validation';
import { UserRole } from '../models/User';

export const createBooking = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = bookingValidation.create.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { student, line, date, pickupStop, dropoffStop, notes } = req.body;
    const parentId = req.user?.userId;

    // Verify student exists and is a student
    const studentUser = await User.findById(student);
    if (!studentUser || studentUser.role !== UserRole.STUDENT) {
      res.status(404).json({ message: 'Student not found or invalid role' });
      return;
    }

    // Verify line exists and is active
    const lineExists = await Line.findById(line);
    if (!lineExists || !lineExists.isActive) {
      res.status(404).json({ message: 'Line not found or inactive' });
      return;
    }

    // Check if line has available capacity
    if (lineExists.currentCapacity >= lineExists.maxCapacity) {
      res.status(400).json({ message: 'Line is at full capacity' });
      return;
    }

    // Check if student already has a booking for this date
    const existingBooking = await Booking.findOne({
      student,
      date,
      status: { $in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] }
    });

    if (existingBooking) {
      res.status(400).json({ message: 'Student already has a booking for this date' });
      return;
    }

    const booking = new Booking({
      student,
      parent: parentId,
      line,
      date,
      pickupStop,
      dropoffStop,
      notes
    });

    await booking.save();

    // Update line capacity
    await Line.findByIdAndUpdate(line, {
      $inc: { currentCapacity: 1 }
    });

    const populatedBooking = await booking.populate([
      { path: 'student', select: 'firstName lastName' },
      { path: 'line', select: 'name startTime endTime' }
    ]);

    res.status(201).json({
      message: 'Booking created successfully',
      booking: populatedBooking
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Server error', error: errorMessage });
  }
};

export const getAllBookings = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, line, date, student } = req.query;
    const filter: any = {};

    if (status) {
      filter.status = status;
    }

    if (line) {
      filter.line = line;
    }

    if (date) {
      filter.date = new Date(date as string);
    }

    if (student) {
      filter.student = student;
    }

    const bookings = await Booking.find(filter).populate([
      { path: 'student', select: 'firstName lastName email' },
      { path: 'parent', select: 'firstName lastName email' },
      { path: 'line', select: 'name startTime endTime' }
    ]);

    res.json({ bookings });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Server error', error: errorMessage });
  }
};

export const getBookingById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const booking = await Booking.findById(id).populate([
      { path: 'student', select: 'firstName lastName email phone' },
      { path: 'parent', select: 'firstName lastName email phone' },
      { path: 'line', select: 'name startTime endTime route driver vehicle' }
    ]);

    if (!booking) {
      res.status(404).json({ message: 'Booking not found' });
      return;
    }

    res.json({ booking });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Server error', error: errorMessage });
  }
};

export const updateBooking = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { error } = bookingValidation.update.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { status, notes } = req.body;
    const updateData: any = {};

    if (status) {
      updateData.status = status;
    }

    if (notes !== undefined) {
      updateData.notes = notes;
    }

    const booking = await Booking.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).populate([
      { path: 'student', select: 'firstName lastName email' },
      { path: 'parent', select: 'firstName lastName email' },
      { path: 'line', select: 'name startTime endTime' }
    ]);

    if (!booking) {
      res.status(404).json({ message: 'Booking not found' });
      return;
    }

    // If booking is cancelled, decrease line capacity
    if (status === BookingStatus.CANCELLED) {
      await Line.findByIdAndUpdate(booking.line, {
        $inc: { currentCapacity: -1 }
      });
    }

    res.json({
      message: 'Booking updated successfully',
      booking
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Server error', error: errorMessage });
  }
};

export const getBookingsByParent = async (req: Request, res: Response): Promise<void> => {
  try {
    const parentId = req.user?.userId;

    const bookings = await Booking.find({ parent: parentId }).populate([
      { path: 'student', select: 'firstName lastName' },
      { path: 'line', select: 'name startTime endTime route' }
    ]);

    res.json({ bookings });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Server error', error: errorMessage });
  }
};

export const getBookingsByLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { lineId } = req.params;
    const { date } = req.query;

    const filter: any = { line: lineId };

    if (date) {
      filter.date = new Date(date as string);
    }

    const bookings = await Booking.find(filter).populate([
      { path: 'student', select: 'firstName lastName' },
      { path: 'parent', select: 'firstName lastName phone' }
    ]);

    res.json({ bookings });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Server error', error: errorMessage });
  }
}; 