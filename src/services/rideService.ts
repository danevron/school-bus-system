import Line from '../models/Line';
import Ride, { RideStatus, StudentRideStatus } from '../models/Ride';
import { ScheduleType } from '../models/Line';

export class RideService {
  /**
   /**
    * Generate rides for a specific line based on its schedule
    */
   static async generateRidesForLine(lineId: string, startDate: Date, endDate: Date): Promise<InstanceType<typeof Ride>[]> {
     const line = await Line.findById(lineId).populate('route');
     if (!line) {
       throw new Error('Line not found');
     }

    const rides: InstanceType<typeof Ride>[] = [];
    const currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      // Check if this date should have a ride based on schedule
      if (this.shouldHaveRideOnDate(line.schedule, currentDate)) {
        // Check if ride already exists for this date
        const existingRide = await Ride.findOne({
          line: lineId,
          date: {
            $gte: new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate()),
            $lt: new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate() + 1)
          }
        });

        if (!existingRide) {
          // Create student ride entries for assigned students
          const studentRides = line.students.map(studentId => ({
            student: studentId,
            status: StudentRideStatus.PENDING,
            pickupStop: (line.route as any)?.stops?.find((stop: any) => stop.type === 'pickup')?._id,
            dropoffStop: (line.route as any)?.stops?.find((stop: any) => stop.type === 'dropoff')?._id
          }));

          const ride = new Ride({
            line: lineId,
            date: new Date(currentDate),
            status: RideStatus.SCHEDULED,
            students: studentRides,
            guests: [],
            driver: line.driver,
            vehicle: line.vehicle,
            route: line.route._id
          });

          await ride.save();
          rides.push(ride);
        }
      }

      // Move to next day
      currentDate.setDate(currentDate.getDate() + 1);
    }

    return rides;
  }

  /**
   * Generate rides for all active lines
   */
  static async generateRidesForAllLines(startDate: Date, endDate: Date): Promise<InstanceType<typeof Ride>[]> {
    const activeLines = await Line.find({ isActive: true });
    const allRides: InstanceType<typeof Ride>[] = [];

    for (const line of activeLines) {
      try {
        const rides = await this.generateRidesForLine(String(line._id), startDate, endDate);
        allRides.push(...rides);
      } catch (error) {
        console.error(`Error generating rides for line ${line._id}:`, error);
      }
    }

    return allRides;
  }

  /**
   * Check if a line should have a ride on a specific date based on its schedule
   */
  private static shouldHaveRideOnDate(schedule: any, date: Date): boolean {
    const dayOfWeek = date.getDay(); // 0 = Sunday, 1 = Monday, etc.

    switch (schedule.type) {
      case ScheduleType.DAILY:
        return true;

      case ScheduleType.WEEKDAYS:
        return dayOfWeek >= 1 && dayOfWeek <= 5; // Monday to Friday

      case ScheduleType.WEEKENDS:
        return dayOfWeek === 0 || dayOfWeek === 6; // Saturday and Sunday

      case ScheduleType.CUSTOM:
        if (schedule.daysOfWeek && schedule.daysOfWeek.length > 0) {
          return schedule.daysOfWeek.includes(dayOfWeek);
        }
        if (schedule.customDates && schedule.customDates.length > 0) {
          const dateString = date.toISOString().split('T')[0];
          return schedule.customDates.some((customDate: Date) => 
            customDate.toISOString().split('T')[0] === dateString
          );
        }
        return false;

      default:
        return false;
    }
  }

  /**
   /**
    * Get rides for a driver on a specific date
    */
   static async getDriverRides(driverId: string, date?: Date): Promise<InstanceType<typeof Ride>[]> {
     const filter: any = { driver: driverId };
     
     if (date) {
       filter.date = {
        $gte: new Date(date.getFullYear(), date.getMonth(), date.getDate()),
        $lt: new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1)
      };
    }

    return await Ride.find(filter)
      .populate('line', 'name description')
      .populate('route', 'name stops')
      .populate('vehicle', 'licensePlate make vehicleModel capacity')
      .populate('students.student', 'firstName lastName')
      .sort({ date: 1, 'line.startTime': 1 });
  }

  /**
   * Get rides for a student
   */
  static async getStudentRides(studentId: string, startDate?: Date, endDate?: Date): Promise<InstanceType<typeof Ride>[]> {
    const filter: any = {
      'students.student': studentId
    };

    if (startDate && endDate) {
      filter.date = {
        $gte: startDate,
        $lte: endDate
      };
    }

    return await Ride.find(filter)
      .populate('line', 'name description')
      .populate('route', 'name stops')
      .populate('driver', 'firstName lastName')
      .sort({ date: 1 });
  }

  /**
   * Calculate available seats for a ride
   */
  static async getAvailableSeats(rideId: string): Promise<number> {
    const ride = await Ride.findById(rideId).populate('vehicle');
    if (!ride) {
      throw new Error('Ride not found');
    }

    const totalPassengers = ride.students.length + ride.guests.length;
    return (ride.vehicle as any).capacity - totalPassengers;
  }
} 