import Ride, { RideStatus } from '../models/Ride';
import RideProgress, { ILocationPoint } from '../models/RideProgress';
import User from '../models/User';
import Booking from '../models/Booking';
import { Types } from 'mongoose';

export class RideProgressService {
  /**
   * Start a ride - can be called by assigned driver or admin
   */
  static async startRide(rideId: string, userId: string): Promise<any> {
    const ride = await Ride.findById(rideId)
      .populate('driver', 'firstName lastName email')
      .populate('vehicle', 'licensePlate make vehicleModel');

    if (!ride) {
      throw new Error('Ride not found');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Check permissions: only assigned driver or admin can start ride
    const isAssignedDriver = ride.driver._id.toString() === userId;
    const isAdmin = user.role === 'admin';

    if (!isAssignedDriver && !isAdmin) {
      throw new Error('Only assigned driver or admin can start this ride');
    }

    // Check if ride can be started
    if (ride.status !== RideStatus.SCHEDULED) {
      throw new Error(`Cannot start ride with status: ${ride.status}`);
    }

    if (ride.actualStartTime) {
      throw new Error('Ride has already been started');
    }

    // Check if progress already exists
    const existingProgress = await RideProgress.findOne({ rideId });
    if (existingProgress) {
      throw new Error('Ride progress already exists');
    }

    // Check if there are any non-cancelled bookings for this ride
    const activeBookings = await Booking.countDocuments({
      ride: rideId,
      status: { $in: ['confirmed', 'checked_in', 'unconfirmed'] }
    });

    if (activeBookings === 0) {
      throw new Error('Cannot start ride with no active bookings');
    }

    // Update ride status and start time
    ride.status = RideStatus.IN_PROGRESS;
    ride.actualStartTime = new Date();
    await ride.save();

    // Create progress record
    const rideProgress = new RideProgress({
      rideId: ride._id,
      driverId: ride.driver._id,
      startedAt: new Date(),
      currentStatus: 'started'
    });

    await rideProgress.save();

    return {
      ride: {
        id: ride._id,
        status: ride.status,
        actualStartTime: ride.actualStartTime,
        route: ride.route
      },
      progress: {
        id: rideProgress._id,
        startedAt: rideProgress.startedAt,
        status: rideProgress.currentStatus
      }
    };
  }

  /**
   * Update ride location - only assigned driver can do this
   */
  static async updateLocation(
    rideId: string, 
    userId: string, 
    locationData: {
      latitude: number;
      longitude: number;
      speed?: number;
      heading?: number;
      accuracy?: number;
    }
  ): Promise<any> {
    const progress = await RideProgress.findOne({ rideId });
    
    if (!progress) {
      throw new Error('Ride progress not found. Ride must be started first.');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Check permissions
    const isAssignedDriver = progress.driverId.toString() === userId;
    const isAdmin = user.role === 'admin';

    if (!isAssignedDriver && !isAdmin) {
      throw new Error('Only assigned driver or admin can end this ride');
    }

    // Check if ride is still active
    if (progress.currentStatus === 'completed') {
      throw new Error('Cannot update location for completed ride');
    }

    // Create location point
    const locationPoint: ILocationPoint = {
      coordinates: {
        latitude: locationData.latitude,
        longitude: locationData.longitude
      },
      timestamp: new Date(),
      speed: locationData.speed,
      heading: locationData.heading,
      accuracy: locationData.accuracy
    };

    // Add location point
    await progress.addLocationPoint(locationPoint);

    return {
      success: true,
      location: locationPoint,
      totalPoints: progress.locationPoints.length
    };
  }

  /**
   * Get ride progress - accessible by driver, admin, and authorized passengers
   */
  static async getRideProgress(rideId: string, userId: string, fromTimestamp?: Date): Promise<any> {
    const ride = await Ride.findById(rideId).populate('driver', 'firstName lastName');
    if (!ride) {
      throw new Error('Ride not found');
    }

    const progress = await RideProgress.findOne({ rideId });
    if (!progress) {
      throw new Error('Ride progress not found');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Check access permissions
    const hasAccess = await this.checkProgressAccess(ride, userId, user);
    if (!hasAccess) {
      throw new Error('Access denied to ride progress');
    }

    // Get current progress data
    const currentProgress = progress.getCurrentProgress();

    // Filter location points based on fromTimestamp if provided
    let filteredLocations = progress.locationPoints;
    if (fromTimestamp) {
      filteredLocations = progress.locationPoints.filter(point => 
        point.timestamp >= fromTimestamp
      );
    } else {
      // Return limited location history (last 50 points to avoid large responses)
      filteredLocations = progress.locationPoints.slice(-50);
    }

    return {
      rideId: ride._id,
      status: progress.currentStatus,
      startedAt: progress.startedAt,
      endedAt: progress.endedAt,
      lastUpdated: progress.lastUpdated,
      currentLocation: currentProgress.currentLocation,
      totalDistance: currentProgress.totalDistance,
      isActive: currentProgress.isActive,
      visitedStops: progress.visitedStops,
      locations: filteredLocations,
      fromTimestamp: fromTimestamp || null
    };
  }

  /**
   * End a ride - can be called by assigned driver or admin
   */
  static async endRide(rideId: string, userId: string): Promise<any> {
    const ride = await Ride.findById(rideId);
    if (!ride) {
      throw new Error('Ride not found');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Check permissions
    const isAssignedDriver = ride.driver.toString() === userId;
    const isAdmin = user.role === 'admin';

    if (!isAssignedDriver && !isAdmin) {
      throw new Error('Only assigned driver or admin can end this ride');
    }

    if (ride.status !== RideStatus.IN_PROGRESS) {
      throw new Error(`Cannot end ride with status: ${ride.status}`);
    }

    const progress = await RideProgress.findOne({ rideId });
    if (!progress) {
      throw new Error('Ride progress not found');
    }

    // Update ride status and end time
    ride.status = RideStatus.COMPLETED;
    ride.actualEndTime = new Date();
    await ride.save();

    // Update progress status
    progress.currentStatus = 'completed';
    progress.endedAt = new Date();
    await progress.save();

    return {
      ride: {
        id: ride._id,
        status: ride.status,
        actualEndTime: ride.actualEndTime
      },
      progress: {
        endedAt: progress.endedAt,
        status: progress.currentStatus
      }
    };
  }

  /**
   * Check if user has access to ride progress data
   */
  private static async checkProgressAccess(ride: any, userId: string, user: any): Promise<boolean> {
    // Admin can access any ride
    if (user.role === 'admin') {
      return true;
    }

    // Assigned driver can access
    if (ride.driver._id.toString() === userId) {
      return true;
    }

    // Check if user has booking for this ride
    const booking = await Booking.findOne({
      ride: ride._id,
      user: userId,
      status: { $in: ['confirmed', 'checked_in'] }
    });

    if (booking) {
      return true;
    }

    // Check if user is parent of student with booking
    if (user.role === 'parent') {
      // Find all bookings for this ride
      const bookings = await Booking.find({
        ride: ride._id,
        status: { $in: ['confirmed', 'checked_in'] }
      });

      // Get passenger IDs from bookings
      const passengerIds = bookings.map(booking => booking.passenger);

      // Query users collection to get passenger data
      const passengers = await User.find({
        _id: { $in: passengerIds },
        role: 'student'
      }, 'parents');

      // Check if any student passenger belongs to this parent
      for (const passenger of passengers) {
        if (passenger.parents && 
            passenger.parents.some((parentId: any) => parentId.toString() === userId)) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * Clean up old progress data (should be run periodically)
   */
  static async cleanupOldProgress(): Promise<{ deletedCount: number }> {
    // Delete progress data for rides completed more than 24 hours ago
    const cutoffDate = new Date();
    cutoffDate.setHours(cutoffDate.getHours() - 24);

    const result = await RideProgress.deleteMany({
      currentStatus: 'completed',
      endedAt: { $lt: cutoffDate }
    });

    return { deletedCount: result.deletedCount || 0 };
  }
}

export default RideProgressService;