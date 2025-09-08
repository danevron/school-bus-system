import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'School Bus System'**
  String get appTitle;

  /// The subtitle of the application
  ///
  /// In en, this message translates to:
  /// **'Mobile App'**
  String get appSubtitle;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hebrew language option
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get hebrew;

  /// Settings menu label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Rides navigation label
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// Notifications navigation label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Driver role label
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// Parent role label
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// Student role label
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// Admin role label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Email field validation - required
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// Email field validation - invalid format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// Password field validation - required
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// Password field validation - too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Temporary message for forgot password feature
  ///
  /// In en, this message translates to:
  /// **'Forgot password feature coming soon'**
  String get forgotPasswordComingSoon;

  /// Generic network error message
  ///
  /// In en, this message translates to:
  /// **'Network error occurred'**
  String get networkError;

  /// Generic login failure message
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Personalized welcome message with user's first name
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {firstName}!'**
  String welcomePersonalized(String firstName);

  /// Personalized welcome description for logged in users
  ///
  /// In en, this message translates to:
  /// **'You\'re successfully logged in to the School Bus System. Manage your rides and stay updated with transportation information.'**
  String get welcomePersonalizedDescription;

  /// Generic welcome description fallback when user data is not available
  ///
  /// In en, this message translates to:
  /// **'Mobile application for school bus transportation management.'**
  String get welcomeFallbackDescription;

  /// Bottom navigation tab for driver's rides
  ///
  /// In en, this message translates to:
  /// **'My Rides'**
  String get myRides;

  /// Title for the my rides screen
  ///
  /// In en, this message translates to:
  /// **'My Rides'**
  String get myRidesTitle;

  /// Message when driver has no rides
  ///
  /// In en, this message translates to:
  /// **'No rides assigned yet'**
  String get myRidesEmpty;

  /// Description for empty rides state
  ///
  /// In en, this message translates to:
  /// **'Your assigned rides will appear here. Contact your administrator if you should have rides assigned.'**
  String get myRidesEmptyDescription;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Ride status - currently active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get rideStatusActive;

  /// Ride status - completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get rideStatusCompleted;

  /// Ride status - cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get rideStatusCancelled;

  /// Ride status - scheduled
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get rideStatusScheduled;

  /// Ride details screen title
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetails;

  /// Start ride button text
  ///
  /// In en, this message translates to:
  /// **'Start Ride'**
  String get startRide;

  /// Starting ride loading text
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get startingRide;

  /// Success message when ride is started
  ///
  /// In en, this message translates to:
  /// **'Ride started successfully'**
  String get rideStartedSuccessfully;

  /// Error message when ride fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start ride'**
  String get failedToStartRide;

  /// Passengers section title
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// Message when no bookings exist for ride
  ///
  /// In en, this message translates to:
  /// **'No bookings for this ride'**
  String get noBookingsForRide;

  /// Booking status - confirmed
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// Booking status - unconfirmed
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed'**
  String get bookingStatusUnconfirmed;

  /// Booking status - checked in
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get bookingStatusCheckedIn;

  /// Booking status - cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// Booking status - completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// Pickup location label
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// Dropoff location label
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get dropoff;

  /// Check in button text
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Success message when booking is updated
  ///
  /// In en, this message translates to:
  /// **'Booking updated successfully'**
  String get bookingUpdatedSuccessfully;

  /// Error message when booking update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update booking'**
  String get failedToUpdateBooking;

  /// Passengers count with number
  ///
  /// In en, this message translates to:
  /// **'Passengers ({count})'**
  String passengersCount(int count);

  /// Drop off button text
  ///
  /// In en, this message translates to:
  /// **'Drop Off'**
  String get dropOff;

  /// Success message when passenger is checked in
  ///
  /// In en, this message translates to:
  /// **'Passenger checked in successfully'**
  String get passengerCheckedInSuccessfully;

  /// Success message when passenger is dropped off
  ///
  /// In en, this message translates to:
  /// **'Passenger dropped off successfully'**
  String get passengerDroppedOffSuccessfully;

  /// End ride button text
  ///
  /// In en, this message translates to:
  /// **'End Ride'**
  String get endRide;

  /// Ending ride loading text
  ///
  /// In en, this message translates to:
  /// **'Ending...'**
  String get endingRide;

  /// Success message when ride is ended
  ///
  /// In en, this message translates to:
  /// **'Ride ended successfully'**
  String get rideEndedSuccessfully;

  /// Error message when ride fails to end
  ///
  /// In en, this message translates to:
  /// **'Failed to end ride'**
  String get failedToEndRide;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
