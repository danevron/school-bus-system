import Ride from '../models/Ride';
import Booking, { BookingStatus } from '../models/Booking';
import StudentAssignment from '../models/StudentAssignment';
import { ILine, ScheduleType } from '../models/Line';

/**
 * Generate rides for an activated line based on its schedule
 * Only generates future rides, not past ones
 * @param line - The line to generate rides for
 * @param limitDate - Optional date to limit ride generation (defaults to line's end date or 1 year from now)
 */
export const generateRidesForLine = async (line: ILine, limitDate?: Date): Promise<any[]> => {
  if (!line.route || !line.route.stops || line.route.stops.length === 0) {
    throw new Error('Line must have a route with stops to generate rides');
  }

  if (!line.students || line.students.length === 0) {
    throw new Error('Line must have assigned students to generate rides');
  }

  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  
  console.log({today});
  const schedule = line.schedule;
  
  // Determine the end date: use the earliest of limitDate, line's end date, or 1 year from now
  let endDate = schedule.endDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year from now if no line end date
  
  if (limitDate) {
    // Use the earlier date between limitDate and the line's end date
    endDate = limitDate < endDate ? limitDate : endDate;
  }
  
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

      const dateString = rideDate.toISOString().split('T')[0];
      const startOfDay = new Date(dateString + 'T00:00:00.000Z');
      const endOfDay = new Date(dateString + 'T23:59:59.999Z');
      
      const existingRide = await Ride.findOne({
        lineId: line._id,
        date: {
          $gte: startOfDay,
          $lt: endOfDay
        }
      });

      console.log({existingRide, startOfDay, endOfDay})
      if (existingRide) {
        continue; // Skip if ride already exists
      }

      // Create the ride
      const rideStartTime = calculateRideStartTime(rideDate, line.rideStartTime);
      
      const newRide = new Ride({
        date: rideDate,
        startTime: rideStartTime,
        route: {
          name: line.name,
          stops: line.route.stops.map(stop => ({
            stopId: stop.stopId,
            name: stop.name,
            address: stop.address,
            coordinates: stop.coordinates,
            type: stop.type
          })),
          estimatedDuration: line.route.estimatedDuration,
          totalDistance: line.route.totalDistance
        },
        driver: line.driver,
        vehicle: line.vehicle,
        maxCapacity: line.maxCapacity,
        availableSeats: line.maxCapacity, // Let booking system manage this dynamically
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

      // Check if student is assigned for this day of the week
      if (assignment.daysOfWeek && assignment.daysOfWeek.length > 0) {
        const rideDayOfWeek = ride.date.getDay(); // 0 = Sunday, 1 = Monday, etc.
        if (!assignment.daysOfWeek.includes(rideDayOfWeek)) {
          return; // Skip if student is not assigned for this day
        }
      }

      // Find pickup stop details
      let pickupStopData = null;
      if (assignment.pickupStop) {
        const pickupStop = line.route!.stops.find(stop => stop.stopId === assignment.pickupStop);
        if (pickupStop) {
          pickupStopData = {
            stopId: pickupStop.stopId,
            name: pickupStop.name,
            address: pickupStop.address
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
            address: dropoffStop.address
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
 * Calculate ride start time by combining ride date with line's start time
 */
function calculateRideStartTime(rideDate: Date, rideStartTime: string): Date {
  const [hours, minutes] = rideStartTime.split(':').map(Number);
  const startTime = new Date(rideDate);
  startTime.setHours(hours, minutes, 0, 0);
  return startTime;
}