// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'School Bus System';

  @override
  String get appSubtitle => 'Mobile App';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get rides => 'Rides';

  @override
  String get notifications => 'Notifications';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get driver => 'Driver';

  @override
  String get parent => 'Parent';

  @override
  String get student => 'Student';

  @override
  String get admin => 'Admin';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get forgotPasswordComingSoon => 'Forgot password feature coming soon';

  @override
  String get networkError => 'Network error occurred';

  @override
  String get loginFailed => 'Login failed';

  @override
  String welcomePersonalized(String firstName) {
    return 'Welcome back, $firstName!';
  }

  @override
  String get welcomePersonalizedDescription =>
      'You\'re successfully logged in to the School Bus System. Manage your rides and stay updated with transportation information.';

  @override
  String get welcomeFallbackDescription =>
      'Mobile application for school bus transportation management.';

  @override
  String get myRides => 'My Rides';

  @override
  String get myRidesTitle => 'My Rides';

  @override
  String get myRidesEmpty => 'No rides assigned yet';

  @override
  String get myRidesEmptyDescription =>
      'Your assigned rides will appear here. Contact your administrator if you should have rides assigned.';

  @override
  String get refresh => 'Refresh';

  @override
  String get rideStatusActive => 'Active';

  @override
  String get rideStatusCompleted => 'Completed';

  @override
  String get rideStatusCancelled => 'Cancelled';

  @override
  String get rideStatusScheduled => 'Scheduled';

  @override
  String get rideDetails => 'Ride Details';

  @override
  String get startRide => 'Start Ride';

  @override
  String get startingRide => 'Starting...';

  @override
  String get rideStartedSuccessfully => 'Ride started successfully';

  @override
  String get failedToStartRide => 'Failed to start ride';

  @override
  String get passengers => 'Passengers';

  @override
  String get noBookingsForRide => 'No bookings for this ride';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusUnconfirmed => 'Unconfirmed';

  @override
  String get bookingStatusCheckedIn => 'Checked In';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get pickup => 'Pickup';

  @override
  String get dropoff => 'Dropoff';

  @override
  String get checkIn => 'Check In';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get bookingUpdatedSuccessfully => 'Booking updated successfully';

  @override
  String get failedToUpdateBooking => 'Failed to update booking';

  @override
  String passengersCount(int count) {
    return 'Passengers ($count)';
  }

  @override
  String get dropOff => 'Drop Off';

  @override
  String get passengerCheckedInSuccessfully =>
      'Passenger checked in successfully';

  @override
  String get passengerDroppedOffSuccessfully =>
      'Passenger dropped off successfully';

  @override
  String get endRide => 'End Ride';

  @override
  String get endingRide => 'Ending...';

  @override
  String get rideEndedSuccessfully => 'Ride ended successfully';

  @override
  String get failedToEndRide => 'Failed to end ride';

  @override
  String get startLocationSharing => 'Start Location Sharing';

  @override
  String get stopLocationSharing => 'Stop Location Sharing';

  @override
  String get locationSharingActive => 'Sharing Location...';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for ride tracking';

  @override
  String get todayRides => 'Today\'s Rides';

  @override
  String get otherRides => 'Other Rides';

  @override
  String get showAll => 'Show All';

  @override
  String get filter => 'Filter';

  @override
  String get noActiveRidesFound => 'No active rides found';

  @override
  String get tapShowAllForCompleted =>
      'Tap \"Show All\" to see completed and cancelled rides';

  @override
  String get bookingConfirmedSuccessfully => 'Booking confirmed successfully';

  @override
  String get bookingCancelledSuccessfully => 'Booking cancelled successfully';

  @override
  String get confirmCancellation => 'Confirm Cancellation';

  @override
  String get confirmCancellationMessage =>
      'Are you sure you want to cancel this booking?';

  @override
  String get bookNewRide => 'Book New Ride';

  @override
  String get bookRideFor => 'Book ride for:';

  @override
  String mePassenger(String firstName) {
    return 'Me ($firstName)';
  }

  @override
  String availableRidesCount(int count) {
    return 'Available Rides ($count)';
  }

  @override
  String seatsAvailable(int available, int total) {
    return '$available/$total seats';
  }

  @override
  String get bookThisRide => 'Book This Ride';

  @override
  String get fullyBooked => 'Fully Booked';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String get ride => 'Ride';

  @override
  String get passenger => 'Passenger';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get rideBookedSuccessfully => 'Ride booked successfully!';

  @override
  String get failedToBookRide => 'Failed to book ride';

  @override
  String get noAvailableRides => 'No available rides';

  @override
  String get checkBackLaterRides =>
      'Check back later for new ride opportunities.';

  @override
  String get selectStops => 'Select Stops:';

  @override
  String get dropoffOptional => 'Dropoff (optional):';

  @override
  String get choosePickupStop => 'Choose pickup stop';

  @override
  String get chooseDropoffStop => 'Choose dropoff stop (optional)';

  @override
  String get noneEndOfRoute => 'None (end of route)';

  @override
  String get pleaseSelectPickupStop => 'Please select a pickup stop';

  @override
  String get trackRide => 'Track Ride';

  @override
  String get rideTracking => 'Ride Tracking';

  @override
  String trackingRide(String rideName) {
    return 'Tracking: $rideName';
  }

  @override
  String get centerOnBus => 'Center on Bus';

  @override
  String get locationUnavailable => 'Location Unavailable';

  @override
  String get noLocationData => 'No location data available for this ride';

  @override
  String get rideNotStarted => 'Ride not found or not started yet';

  @override
  String get errorLoadingLocation => 'Error loading ride location';

  @override
  String get retry => 'Retry';

  @override
  String get rideInProgress => 'Ride In Progress';

  @override
  String driverLabel(String firstName, String lastName) {
    return 'Driver: $firstName $lastName';
  }

  @override
  String vehicleLabel(String licensePlate, String make, String model) {
    return 'Vehicle: $licensePlate ($make $model)';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get unknownTime => 'Unknown';
}
