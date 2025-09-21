import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/ride_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/location_foreground_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await AuthService.init();
  LocationForegroundService.initializeService();
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Failed to initialize NotificationService: $e');
    // Continue without notifications for now
  }
  
  runApp(const SchoolBusApp());
}

class SchoolBusApp extends StatefulWidget {
  const SchoolBusApp({super.key});

  @override
  State<SchoolBusApp> createState() => _SchoolBusAppState();
}

class _SchoolBusAppState extends State<SchoolBusApp> {
  Locale _locale = const Locale('en', '');
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Provide navigator key to notification service for deep linking
    NotificationService.navigatorKey = _navigatorKey;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load saved locale preference
    await _loadSavedLocale();
    
    // Add a minimum splash screen duration
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('language_code');
      
      if (savedLanguageCode != null) {
        setState(() {
          _locale = Locale(savedLanguageCode, '');
        });
      } else {
        // If no saved preference, try to use system locale
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        if (systemLocale.languageCode == 'he') {
          setState(() {
            _locale = const Locale('he', '');
          });
        }
      }
    } catch (e) {
      // If there's an error loading preferences, keep the default English locale
      print('Error loading saved locale: $e');
    }
  }

  void _changeLanguage(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    
    // Save the language preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
    }
  }

  void _onAuthChanged() {
    setState(() {
      // Trigger rebuild when auth state changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'School Bus App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
          surface: Colors.white,
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
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
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
        '/': (context) => _isInitialized 
            ? (AuthService.isAuthenticated 
                ? MainNavigationScreen(onLanguageChange: _changeLanguage, onAuthChanged: _onAuthChanged)
                : LoginScreen(onAuthChanged: _onAuthChanged, onLanguageChange: _changeLanguage))
            : const SplashScreen(),
        '/login': (context) => LoginScreen(onAuthChanged: _onAuthChanged, onLanguageChange: _changeLanguage),
        '/home': (context) => MainNavigationScreen(onLanguageChange: _changeLanguage, onAuthChanged: _onAuthChanged),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/ride-detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args['ride'] != null) {
            return MaterialPageRoute(
              builder: (context) => RideDetailScreen(ride: args['ride']),
            );
          }
        }
        return null;
      },
      initialRoute: '/',
    );
  }
}
