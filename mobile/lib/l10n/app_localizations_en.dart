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
  String get welcomeTitle => '🚌 Welcome to School Bus App!';

  @override
  String get welcomeDescription =>
      'This mobile app will help drivers track rides and parents monitor their children\'s transportation.';

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
}
