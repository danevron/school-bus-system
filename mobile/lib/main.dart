import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
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
