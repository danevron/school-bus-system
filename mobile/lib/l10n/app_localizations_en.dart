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
}
