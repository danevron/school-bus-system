// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'מערכת הסעות';

  @override
  String get appSubtitle => 'בית הספר זומר';

  @override
  String get language => 'שפה';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get settings => 'הגדרות';

  @override
  String get home => 'בית';

  @override
  String get profile => 'פרופיל';

  @override
  String get rides => 'נסיעות';

  @override
  String get notifications => 'התראות';

  @override
  String get login => 'התחברות';

  @override
  String get logout => 'התנתקות';

  @override
  String get email => 'דוא\"ל';

  @override
  String get password => 'סיסמה';

  @override
  String get forgotPassword => 'שכחת סיסמה?';

  @override
  String get driver => 'נהג';

  @override
  String get parent => 'הורה';

  @override
  String get student => 'תלמיד';

  @override
  String get admin => 'מנהל';

  @override
  String get emailRequired => 'נא להזין כתובת אימייל';

  @override
  String get emailInvalid => 'נא להזין כתובת אימייל תקינה';

  @override
  String get passwordRequired => 'נא להזין סיסמה';

  @override
  String get passwordTooShort => 'הסיסמה חייבת להכיל לפחות 6 תווים';

  @override
  String get forgotPasswordComingSoon => 'תכונת שחזור סיסמה תגיע בקרוב';

  @override
  String get networkError => 'אירעה שגיאת רשת';

  @override
  String get loginFailed => 'הכניסה נכשלה';

  @override
  String welcomePersonalized(String firstName) {
    return 'ברוך הבא, $firstName!';
  }

  @override
  String get welcomePersonalizedDescription =>
      'התחברת בהצלחה למערכת ההסעות. נהל את הנסיעות שלך והישאר מעודכן עם מידע תחבורתי.';

  @override
  String get welcomeFallbackDescription => 'אפליקציה לניהול הסעות בית ספר.';

  @override
  String get myRides => 'הנסיעות שלי';

  @override
  String get myRidesTitle => 'הנסיעות שלי';

  @override
  String get myRidesEmpty => 'עדיין לא הוקצו נסיעות';

  @override
  String get myRidesEmptyDescription =>
      'הנסיעות שהוקצו לך יופיעו כאן. פנה למנהל המערכת אם אמורות להיות לך נסיעות מוקצות.';

  @override
  String get refresh => 'רענן';

  @override
  String get rideStatusActive => 'פעיל';

  @override
  String get rideStatusCompleted => 'הושלם';

  @override
  String get rideStatusCancelled => 'בוטל';

  @override
  String get rideStatusScheduled => 'מתוכנן';

  @override
  String get rideDetails => 'פרטי נסיעה';

  @override
  String get startRide => 'התחל נסיעה';

  @override
  String get startingRide => 'מתחיל...';

  @override
  String get rideStartedSuccessfully => 'הנסיעה החלה בהצלחה';

  @override
  String get failedToStartRide => 'נכשל בהתחלת הנסיעה';

  @override
  String get passengers => 'נוסעים';

  @override
  String get noBookingsForRide => 'אין הזמנות לנסיעה זו';

  @override
  String get bookingStatusConfirmed => 'מאושר';

  @override
  String get bookingStatusUnconfirmed => 'לא מאושר';

  @override
  String get bookingStatusCheckedIn => 'עלה לאוטובוס';

  @override
  String get bookingStatusCancelled => 'בוטל';

  @override
  String get bookingStatusCompleted => 'הושלם';

  @override
  String get pickup => 'עליה';

  @override
  String get dropoff => 'ירידה';

  @override
  String get checkIn => 'עליה לאוטובוס';

  @override
  String get confirm => 'אשר';

  @override
  String get cancel => 'בטל';

  @override
  String get bookingUpdatedSuccessfully => 'ההזמנה עודכנה בהצלחה';

  @override
  String get failedToUpdateBooking => 'נכשל בעדכון ההזמנה';

  @override
  String passengersCount(int count) {
    return 'נוסעים ($count)';
  }

  @override
  String get dropOff => 'ירידה מהאוטובוס';

  @override
  String get passengerCheckedInSuccessfully => 'הנוסע עלה לאוטובוס בהצלחה';

  @override
  String get passengerDroppedOffSuccessfully => 'הנוסע ירד מהאוטובוס בהצלחה';

  @override
  String get endRide => 'סיים נסיעה';

  @override
  String get endingRide => 'מסיים...';

  @override
  String get rideEndedSuccessfully => 'הנסיעה הסתיימה בהצלחה';

  @override
  String get failedToEndRide => 'נכשל בסיום הנסיעה';

  @override
  String get startLocationSharing => 'התחל שיתוף מיקום';

  @override
  String get stopLocationSharing => 'הפסק שיתוף מיקום';

  @override
  String get locationSharingActive => 'משתף מיקום...';

  @override
  String get locationPermissionRequired => 'נדרשת הרשאת מיקום למעקב אחר הנסיעה';
}
