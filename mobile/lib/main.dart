import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_navigation_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/location_foreground_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await AuthService.init();
  LocationForegroundService.initializeService();
  
  runApp(const SchoolBusApp());
}

class SchoolBusApp extends StatefulWidget {
  const SchoolBusApp({super.key});

  @override
  State<SchoolBusApp> createState() => _SchoolBusAppState();
}

class _SchoolBusAppState extends State<SchoolBusApp> {
  Locale _locale = const Locale('en', '');

  @override
  void initState() {
    super.initState();
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _onAuthChanged() {
    setState(() {
      // Trigger rebuild when auth state changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Bus App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.rubikTextTheme().copyWith(
          displayLarge: GoogleFonts.rubik(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -0.5),
          displayMedium: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -0.5),
          displaySmall: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0),
          headlineLarge: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: 0),
          headlineMedium: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0),
          headlineSmall: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0),
          titleLarge: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0),
          titleMedium: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          titleSmall: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          bodyLarge: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0),
          bodyMedium: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0),
          bodySmall: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            minimumSize: Size.fromHeight(48),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A1A),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFFFFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.rubikTextTheme().copyWith(
          displayLarge: GoogleFonts.rubik(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -0.5),
          displayMedium: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -0.5),
          displaySmall: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0),
          headlineLarge: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: 0),
          headlineMedium: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0),
          headlineSmall: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0),
          titleLarge: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0),
          titleMedium: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          titleSmall: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          bodyLarge: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0),
          bodyMedium: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0),
          bodySmall: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF404040), width: 1),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF404040), width: 1),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF5252), width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            minimumSize: Size.fromHeight(48),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('he', ''), // Hebrew
      ],
      routes: {
        '/': (context) => AuthService.isAuthenticated 
            ? MainNavigationScreen(onLanguageChange: _changeLanguage, onAuthChanged: _onAuthChanged)
            : LoginScreen(onAuthChanged: _onAuthChanged, onLanguageChange: _changeLanguage),
        '/login': (context) => LoginScreen(onAuthChanged: _onAuthChanged, onLanguageChange: _changeLanguage),
        '/home': (context) => MainNavigationScreen(onLanguageChange: _changeLanguage, onAuthChanged: _onAuthChanged),
      },
      initialRoute: '/',
    );
  }
}
