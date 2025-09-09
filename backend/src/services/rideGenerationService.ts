import Ride from '../models/Ride';
import Booking, { BookingStatus } from '../models/Booking';
import StudentAssignment from '../models/StudentAssignment';
import { ILine, ScheduleType } from '../models/Line';
import { Types } from 'mongoose';

/**
 * Generate rides for an activated line based on its schedule
 * Only generates future rides, not past ones
 */
export const generateRidesForLine = async (line: ILine): Promise<any[]> => {
  if (!line.route || !line.route.stops || line.route.stops.length === 0) {
    throw new Error('Line must have a route with stops to generate rides');
  }

  if (!line.students || line.students.length === 0) {
    throw new Error('Line must have assigned students to generate rides');
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0); // Start of today
  
  const schedule = line.schedule;
  const endDate = schedule.endDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year from now if no end date
  
  const rideDates = generateRideDates(schedule, today, endDate);
  const generatedRides: any[] = [];

  // Get all active student assignments for this line
  const studentAssignments = await StudentAssignment.find({
    line: line._id,
    isActive: true
  });

  for (const rideDate of rideDates) {
    try {
      // Check if a ride already exists for this line and date
      const existingRide = await Ride.findOne({
        lineId: line._id,
        date: {
          $gte: new Date(rideDate.setHours(0, 0, 0, 0)),
          $lt: new Date(rideDate.setHours(23, 59, 59, 999))
        }
      });

      if (existingRide) {
        continue; // Skip if ride already exists
      }

      // Create the ride
      const newRide = new Ride({
        date: rideDate,
        route: {
          name: line.name,
          stops: line.route.stops.map(stop => ({
            stopId: stop.stopId,
            name: stop.name,
            address: stop.address,
            coordinates: stop.coordinates,
            estimatedArrivalTime: calculateEstimatedArrivalTime(rideDate, stop.estimatedTime),
            type: stop.type
          })),
          estimatedDuration: line.route.estimatedDuration,
          totalDistance: line.route.totalDistance
        },
        driver: line.driver,
        vehicle: line.vehicle,
        maxCapacity: line.maxCapacity,
        availableSeats: Math.max(0, line.maxCapacity - studentAssignments.length), // Calculate based on assignments
        lineId: line._id,
        notes: `Generated from line: ${line.name}`,
        createdBy: line.driver // Use driver as creator for generated rides
      });

      const savedRide = await newRide.save();
      
      // Create bookings for all assigned students
      await createBookingsForStudents(savedRide, studentAssignments, line);
      
      generatedRides.push(savedRide);
    } catch (error) {
      console.error(`Failed to create ride for date ${rideDate}:`, error);
      // Continue with other dates even if one fails
    }
  }

  return generatedRides;
};

/**
 * Generate array of dates based on schedule type and parameters
 */
function generateRideDates(schedule: any, startDate: Date, endDate: Date): Date[] {
  const dates: Date[] = [];
  const current = new Date(Math.max(startDate.getTime(), schedule.startDate.getTime()));
  
  while (current <= endDate) {
    let shouldInclude = false;

    switch (schedule.type) {
      case ScheduleType.DAILY:
        shouldInclude = true;
        break;

      case ScheduleType.WEEKDAYS:
        // Monday = 1, Friday = 5
        const weekday = current.getDay();
        shouldInclude = weekday >= 1 && weekday <= 5;
        break;

      case ScheduleType.WEEKENDS:
        // Saturday = 6, Sunday = 0
        const weekendDay = current.getDay();
        shouldInclude = weekendDay === 0 || weekendDay === 6;
        break;

      case ScheduleType.CUSTOM:
        if (schedule.daysOfWeek && schedule.daysOfWeek.length > 0) {
          // Check if current day of week is in the specified days
          shouldInclude = schedule.daysOfWeek.includes(current.getDay());
        } else if (schedule.customDates && schedule.customDates.length > 0) {
          // Check if current date is in the custom dates
          const currentDateString = current.toISOString().split('T')[0];
          shouldInclude = schedule.customDates.some((customDate: Date) => {
            const customDateString = new Date(customDate).toISOString().split('T')[0];
            return currentDateString === customDateString;
          });
        }
        break;
    }

    if (shouldInclude) {
      dates.push(new Date(current));
    }

    // Move to next day
    current.setDate(current.getDate() + 1);
  }

  return dates;
}

/**
 * Create bookings for all assigned students for a specific ride
 */
async function createBookingsForStudents(ride: any, studentAssignments: any[], line: ILine): Promise<void> {
  const bookingPromises = studentAssignments.map(async (assignment) => {
    try {
      // Check if booking already exists for this student and ride
      const existingBooking = await Booking.findOne({
        ride: ride._id,
        passenger: assignment.student
      });

      if (existingBooking) {
        return; // Skip if booking already exists
      }

      // Find pickup stop details
      let pickupStopData = null;
      if (assignment.pickupStop) {
        const pickupStop = line.route!.stops.find(stop => stop.stopId === assignment.pickupStop);
        if (pickupStop) {
          pickupStopData = {
            stopId: pickupStop.stopId,
            name: pickupStop.name,
            address: pickupStop.address,
            estimatedTime: calculateEstimatedArrivalTime(ride.date, pickupStop.estimatedTime)
          };
        }
      }

      // Find dropoff stop details
      let dropoffStopData = null;
      if (assignment.dropoffStop) {
        const dropoffStop = line.route!.stops.find(stop => stop.stopId === assignment.dropoffStop);
        if (dropoffStop) {
          dropoffStopData = {
            stopId: dropoffStop.stopId,
            name: dropoffStop.name,
            address: dropoffStop.address,
            estimatedTime: calculateEstimatedArrivalTime(ride.date, dropoffStop.estimatedTime)
          };
        }
      }

      // Create the booking
      const newBooking = new Booking({
        ride: ride._id,
        passenger: assignment.student,
        pickupStop: pickupStopData,
        dropoffStop: dropoffStopData,
        status: BookingStatus.UNCONFIRMED, // Create as unconfirmed for assigned students
        notes: `Auto-generated for assigned student from line: ${line.name}`,
        createdBy: ride.createdBy
      });

      await newBooking.save();
    } catch (error) {
      console.error(`Failed to create booking for student ${assignment.student}:`, error);
      // Continue with other students even if one fails
    }
  });

  await Promise.allSettled(bookingPromises);
}

/**
 * Calculate estimated arrival time for a stop based on ride date and estimated time offset
 */
function calculateEstimatedArrivalTime(rideDate: Date, estimatedTimeOffset: number): Date {
  const arrivalTime = new Date(rideDate);
  
  // Assume rides start at 7:00 AM by default
  arrivalTime.setHours(7, 0, 0, 0);
  
  // Add the estimated time offset in minutes
  arrivalTime.setMinutes(arrivalTime.getMinutes() + estimatedTimeOffset);
  
  return arrivalTime;
}