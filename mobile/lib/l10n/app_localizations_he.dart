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
  String get welcomeTitle => '🚌 ברוכים הבאים לאפליקציית ההסעות!';

  @override
  String get welcomeDescription =>
      'אפליקציה זו תעזור לנהגים לשתף נסיעות ולהורים לעקוב אחר הסעות ילדיהם.';

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
}
