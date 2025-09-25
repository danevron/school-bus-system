import { Request, Response } from 'express';
import { Types } from 'mongoose';
import Booking, { BookingStatus } from '../models/Booking';
import Ride, { RideStatus } from '../models/Ride';
import User, { UserRole } from '../models/User';
import { bookingValidation } from '../utils/validation';

export const bookingController = {
  // Get all bookings (Admin only)
  getAllBookings: async (req: Request, res: Response) => {
    try {
      const { status, rideId, passengerId } = req.query;
      
      const filter: any = {};
      
      if (status) {
        filter.status = status;
      }
      
      if (rideId) {
        filter.ride = rideId;
      }
      
      if (passengerId) {
        filter.passenger = passengerId;
      }
      
      const bookings = await Booking.find(filter)
        .populate('ride', 'date startTime route status')
        .populate('createdBy', 'firstName lastName')
        .populate('confirmedBy', 'firstName lastName')
        .populate('cancelledBy', 'firstName lastName')
        .sort({ bookingDate: -1 });

      // Manually fetch passenger details from Users collection
      const bookingsWithPassengers = await Promise.all(
        bookings.map(async (booking) => {
          const passenger = await User.findById(booking.passenger, 'firstName lastName phone email role');
          return {
            ...booking.toObject(),
            passenger
          };
        })
      );
      
      res.json({
        message: 'Bookings retrieved successfully',
        data: { bookings: bookingsWithPassengers }
      });
    } catch (error) {
      console.error('Error getting bookings:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve bookings',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Get booking by ID
  getBookingById: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      
      const booking = await Booking.findById(id)
        .populate('ride', 'date startTime route status driver vehicle')
        .populate('createdBy', 'firstName lastName')
        .populate('confirmedBy', 'firstName lastName')
        .populate('cancelledBy', 'firstName lastName')
        .populate('checkedInBy', 'firstName lastName')
        .populate('droppedOffBy', 'firstName lastName');
      
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const passenger = await User.findById(booking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...booking.toObject(),
        passenger
      };
      
      res.json({
        message: 'Booking retrieved successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error getting booking:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve booking',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Create booking (Any user can book for themselves, Admins can book for anyone)
  createBooking: async (req: Request, res: Response) => {
    try {
      const { error } = bookingValidation.create.validate(req.body);
      if (error) {
        return res.status(400).json({ message: error.details[0].message });
      }

      const {
        rideId,
        passengerId,
        pickupStop,
        dropoffStop,
        notes
      } = req.body;

      const currentUserId = req.user?.userId;
      const currentUserRole = req.user?.role;

      // Validate ride exists and can be booked
      const ride = await Ride.findById(rideId);
      if (!ride) {
        return res.status(404).json({ message: 'Ride not found' });
      }

      // Validate passenger exists
      const passenger = await User.findById(passengerId);
      if (!passenger) {
        return res.status(404).json({ message: 'Passenger not found' });
      }

      const canBookResult = ride.canBeBooked();
      let bookingStatus = BookingStatus.UNCONFIRMED;
      
      // If ride can't be booked due to no available seats, add to waiting list
      if (!canBookResult.canBook) {
        if (canBookResult.reason === 'No available seats') {
          bookingStatus = BookingStatus.WAITING_LIST;
        } else {
          return res.status(400).json({ message: canBookResult.reason });
        }
      }

      const user = await User.findById(currentUserId).populate('children');

      let isCurrentUserChild = false;
      // If current user is a parent, ensure the passenger is one of their children
      if (currentUserRole === UserRole.PARENT && user?.children) {
        isCurrentUserChild = user.children.some((child) => 
          child._id.toString() === passengerId
        );
      }

      // Check if passenger is a guest created by current user
      let isCurrentUserGuest = false;
      if (passenger.isGuest && passenger.invitedBy) {
        isCurrentUserGuest = passenger.invitedBy.toString() === currentUserId;
      }

      // Authorization check: Users can only book for themselves, their children, or their guests unless they're admin
      if (currentUserRole !== UserRole.ADMIN && 
          (passengerId !== currentUserId && !isCurrentUserChild && !isCurrentUserGuest)) {
        return res.status(403).json({ message: 'You can only create bookings for yourself, your children, or guests you created' });
      }

      // Check if passenger already has a booking for this ride (excluding cancelled ones)
      const existingBooking = await Booking.findOne({
        ride: rideId,
        passenger: passengerId,
        status: { $ne: BookingStatus.CANCELLED }
      });

      if (existingBooking) {
        return res.status(400).json({ message: 'Passenger already has a booking for this ride' });
      }

      // Validate pickup stop exists in ride route
      const pickupStopDetails = ride.route.stops.find(stop => stop.stopId === pickupStop.stopId);
      if (!pickupStopDetails) {
        return res.status(400).json({ message: 'Invalid pickup stop for this ride' });
      }

      // Validate dropoff stop if provided
      let dropoffStopDetails = null;
      if (dropoffStop && dropoffStop.stopId) {
        dropoffStopDetails = ride.route.stops.find(stop => stop.stopId === dropoffStop.stopId);
        if (!dropoffStopDetails) {
          return res.status(400).json({ message: 'Invalid dropoff stop for this ride' });
        }
      }

      const newBooking = new Booking({
        ride: rideId,
        passenger: passengerId,
        pickupStop: {
          stopId: pickupStopDetails.stopId,
          name: pickupStopDetails.name,
          address: pickupStopDetails.address,
          estimatedTime: pickupStopDetails.estimatedArrivalTime
        },
        dropoffStop: dropoffStopDetails ? {
          stopId: dropoffStopDetails.stopId,
          name: dropoffStopDetails.name,
          address: dropoffStopDetails.address,
          estimatedTime: dropoffStopDetails.estimatedArrivalTime
        } : undefined,
        status: bookingStatus,
        notes,
        createdBy: currentUserId
      });

      const savedBooking = await newBooking.save();
      
      const populatedBooking = await Booking.findById(savedBooking._id)
        .populate('ride', 'date startTime route status')
        .populate('createdBy', 'firstName lastName');

      if (!populatedBooking) {
        return res.status(404).json({ message: 'Created booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const passengerData = await User.findById(populatedBooking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...populatedBooking.toObject(),
        passenger: passengerData
      };

      res.status(201).json({
        message: 'Booking created successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error creating booking:', error);
      res.status(500).json({ 
        message: 'Failed to create booking',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Confirm booking (Admin only)
  confirmBooking: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const currentUserId = req.user?.userId;

      const booking = await Booking.findById(id);
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      if (booking.status !== BookingStatus.UNCONFIRMED) {
        return res.status(400).json({ message: 'Only unconfirmed bookings can be confirmed' });
      }

      await booking.confirm(new Types.ObjectId(currentUserId));
      
      const populatedBooking = await Booking.findById(id)
        .populate('ride', 'date startTime route status')
        .populate('confirmedBy', 'firstName lastName');

      if (!populatedBooking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const passengerDetails = await User.findById(populatedBooking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...populatedBooking.toObject(),
        passenger: passengerDetails
      };

      res.json({
        message: 'Booking confirmed successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error confirming booking:', error);
      res.status(500).json({ 
        message: 'Failed to confirm booking',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Cancel booking (Passenger can cancel their own, Admin can cancel any)
  cancelBooking: async (req: Request, res: Response) => {
    try {
      const { error } = bookingValidation.cancel.validate(req.body);
      if (error) {
        return res.status(400).json({ message: error.details[0].message });
      }

      const { id } = req.params;
      const { reason } = req.body;
      const currentUserId = req.user?.userId;
      const currentUserRole = req.user?.role;

      const booking = await Booking.findById(id).populate('passenger', 'isGuest invitedBy');
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      if (!booking.passenger) {
        return res.status(404).json({ message: 'Passenger not found' });
      }

      const passenger = booking.passenger as any;
      // Authorization check: Admin, passenger themselves, or parent of the passenger
      let canCancel = false;
      
      if (currentUserRole === UserRole.ADMIN) {
        canCancel = true;
      } else if (booking.passenger._id.toString() === currentUserId) {
        canCancel = true;
      } else if (passenger.isGuest && passenger.invitedBy?.toString() === currentUserId) {
        // Current user is the one who created this guest passenger
        canCancel = true;
      } else if (currentUserRole === UserRole.PARENT) {
        // Check if current user is a parent of the passenger
        const currentUser = await User.findById(currentUserId);
        if (currentUser?.children) {
          canCancel = currentUser.children.some(childId => 
            childId.toString() === booking.passenger._id.toString()
          );
        }
      }
      
      if (!canCancel) {
        return res.status(403).json({ message: 'You can only cancel your own bookings or your children\'s bookings' });
      }

      const canCancelResult = booking.canBeCancelled();
      if (!canCancelResult.canCancel) {
        return res.status(400).json({ message: canCancelResult.reason });
      }

      await booking.cancel(new Types.ObjectId(currentUserId), reason);
      
      const populatedBooking = await Booking.findById(id)
        .populate('ride', 'date startTime route status')
        .populate('cancelledBy', 'firstName lastName');

      if (!populatedBooking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const passengerInfo = await User.findById(populatedBooking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...populatedBooking.toObject(),
        passenger: passengerInfo
      };

      res.json({
        message: 'Booking cancelled successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error cancelling booking:', error);
      res.status(500).json({ 
        message: 'Failed to cancel booking',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Check in passenger (Driver only)
  checkInPassenger: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const driverId = req.user?.userId;

      const booking = await Booking.findById(id).populate('ride');
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      const ride = booking.ride as any;
      
      // Verify the driver is assigned to this ride
      if (ride.driver.toString() !== driverId) {
        return res.status(403).json({ message: 'You are not assigned to this ride' });
      }

      // Verify ride is in progress
      if (ride.status !== RideStatus.IN_PROGRESS) {
        return res.status(400).json({ message: 'Ride is not in progress' });
      }

      if (booking.status !== BookingStatus.CONFIRMED && booking.status !== BookingStatus.UNCONFIRMED) {
        return res.status(400).json({ message: 'Only confirmed or unconfirmed bookings can be checked in' });
      }

      await booking.checkIn(new Types.ObjectId(driverId));
      
      const populatedBooking = await Booking.findById(id)
        .populate('ride', 'date startTime route status')
        .populate('checkedInBy', 'firstName lastName');

      if (!populatedBooking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const checkedInPassenger = await User.findById(populatedBooking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...populatedBooking.toObject(),
        passenger: checkedInPassenger
      };

      res.json({
        message: 'Passenger checked in successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error checking in passenger:', error);
      res.status(500).json({ 
        message: 'Failed to check in passenger',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Drop off passenger (Driver only)
  dropOffPassenger: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const driverId = req.user?.userId;

      const booking = await Booking.findById(id).populate('ride');
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      const ride = booking.ride as any;
      
      // Verify the driver is assigned to this ride
      if (ride.driver.toString() !== driverId) {
        return res.status(403).json({ message: 'You are not assigned to this ride' });
      }

      if (booking.status !== BookingStatus.CHECKED_IN) {
        return res.status(400).json({ message: 'Passenger must be checked in before drop off' });
      }

      await booking.dropOff(new Types.ObjectId(driverId));
      
      const populatedBooking = await Booking.findById(id)
        .populate('ride', 'date startTime route status')
        .populate('droppedOffBy', 'firstName lastName');

      if (!populatedBooking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const droppedOffPassenger = await User.findById(populatedBooking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...populatedBooking.toObject(),
        passenger: droppedOffPassenger
      };

      res.json({
        message: 'Passenger dropped off successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error dropping off passenger:', error);
      res.status(500).json({ 
        message: 'Failed to drop off passenger',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  getRideBookings: async (req: Request, res: Response) => {
    try {
      const { rideId } = req.params;
      const currentUserRole = req.user?.role;
      const currentUserId = req.user?.userId;
      const ride = await Ride.findById(rideId);

      // If user is driver, verify they're assigned to this ride
      if (currentUserRole === UserRole.DRIVER) {
        if (!ride || ride.driver.toString() !== currentUserId) {
          return res.status(403).json({ message: 'You are not assigned to this ride' });
        }
      }

      const bookings = await Booking.find({ ride: rideId }).populate({
        path: 'passenger',
        select: 'firstName lastName phone email role isGuest invitedBy parents',
        populate: [
          {
            path: 'parents',
            select: 'firstName lastName phone email'
          },
          {
            path: 'invitedBy',
            select: 'firstName lastName email phone'
          }
        ]
      }) as any[];

      // Get current user details to check parent-child relationships
      const currentUser = await User.findById(currentUserId);
      if (!currentUser) {
        return res.status(404).json({ message: 'User not found' });
      }

      // Manually fetch passenger details from Users collection and add action permissions
      const bookingsWithPassengers = await Promise.all(
        bookings.map(async (booking) => {
          
          // Calculate action permissions for this booking
          const actions = {
            canCancel: false,
            canConfirm: false,
            canCheckIn: false,
            canDropOff: false
          };

          if (ride?.status === RideStatus.COMPLETED) {

          }
          // Admin can perform all actions on all bookings
          else if (currentUserRole === UserRole.ADMIN) {
            actions.canCancel = booking.canBeCancelled().canCancel;
            actions.canConfirm = booking.status === BookingStatus.UNCONFIRMED || booking.status === BookingStatus.WAITING_LIST;
            actions.canCheckIn = ride?.status === RideStatus.IN_PROGRESS && (booking.status === BookingStatus.CONFIRMED || booking.status === BookingStatus.UNCONFIRMED);
            actions.canDropOff = ride?.status === RideStatus.IN_PROGRESS && booking.status === BookingStatus.CHECKED_IN;
          }
          // Driver can check in and drop off all bookings on their ride
          else if (currentUserRole === UserRole.DRIVER) {
            actions.canCheckIn = ride?.status === RideStatus.IN_PROGRESS && (booking.status === BookingStatus.CONFIRMED || booking.status === BookingStatus.UNCONFIRMED);
            actions.canDropOff = ride?.status === RideStatus.IN_PROGRESS && booking.status === BookingStatus.CHECKED_IN;
          }
          // Guest's creator can cancel and confirm the guest's bookings
          else if (booking.passenger?.isGuest && booking.passenger?.invitedBy._id.toString() === currentUserId)  {
            actions.canCancel = booking.canBeCancelled().canCancel;
            actions.canConfirm = booking.status === BookingStatus.UNCONFIRMED;
          }
          // Student/Parent can cancel and confirm their own bookings or their children's bookings
          else if (currentUserRole === UserRole.STUDENT || currentUserRole === UserRole.PARENT) {
            const isOwnBooking = booking.passenger.toString() === currentUserId;
            let isChildBooking = false;
            
            // Check if this is a parent's child's booking
            if (currentUserRole === UserRole.PARENT && currentUser.children) {
              isChildBooking = currentUser.children.some(childId => 
                childId.toString() === booking.passenger._id.toString()
              );
            }
            
            if (isOwnBooking || isChildBooking) {
              actions.canCancel = booking.canBeCancelled().canCancel;
              actions.canConfirm = booking.status === BookingStatus.UNCONFIRMED;
            }
          } 

          return {
            ...booking.toObject(),
            actions
          };
        })
      );

      res.json({
        message: 'Ride bookings retrieved successfully',
        data: { bookings: bookingsWithPassengers }
      });
    } catch (error) {
      console.error('Error getting ride bookings:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve ride bookings',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Admit waiting list booking (Admin only)
  admitWaitingListBooking: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const currentUserId = req.user?.userId;

      const booking = await Booking.findById(id);
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      if (booking.status !== BookingStatus.WAITING_LIST) {
        return res.status(400).json({ message: 'Only waiting list bookings can be admitted' });
      }

      // Check if ride still has available seats
      const ride = await Ride.findById(booking.ride);
      if (!ride || ride.availableSeats <= 0) {
        return res.status(400).json({ message: 'No available seats on this ride' });
      }

      await booking.admit(new Types.ObjectId(currentUserId));
      
      const populatedBooking = await Booking.findById(id)
        .populate('ride', 'date startTime route status');

      if (!populatedBooking) {
        return res.status(404).json({ message: 'Booking not found' });
      }

      // Manually fetch passenger details from Users collection
      const passengerDetails = await User.findById(populatedBooking.passenger, 'firstName lastName phone email role');
      const bookingWithPassenger = {
        ...populatedBooking.toObject(),
        passenger: passengerDetails
      };

      res.json({
        message: 'Waiting list booking admitted successfully',
        data: { booking: bookingWithPassenger }
      });
    } catch (error) {
      console.error('Error admitting waiting list booking:', error);
      res.status(500).json({ 
        message: 'Failed to admit waiting list booking',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  },

  // Get user's bookings
  getUserBookings: async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const currentUserId = req.user?.userId;
      const currentUserRole = req.user?.role;

      // Users can only see their own bookings unless they're admin
      if (currentUserRole !== UserRole.ADMIN && userId !== currentUserId) {
        return res.status(403).json({ message: 'You can only view your own bookings' });
      }

      const { status } = req.query;
      const filter: any = { passenger: userId };
      
      if (status) {
        filter.status = status;
      }

      const bookings = await Booking.find(filter)
        .populate('ride', 'date startTime route status driver vehicle')
        .sort({ bookingDate: -1 });

      res.json({
        message: 'User bookings retrieved successfully',
        data: { bookings }
      });
    } catch (error) {
      console.error('Error getting user bookings:', error);
      res.status(500).json({ 
        message: 'Failed to retrieve user bookings',
        error: process.env.NODE_ENV === 'development' ? error : 'Internal server error'
      });
    }
  }
};