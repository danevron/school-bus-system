import 'package:flutter/material.dart';
import 'package:school_bus_app/l10n/app_localizations.dart';
import 'package:school_bus_app/services/auth_service.dart';

class WelcomeScreen extends StatelessWidget {
  final Function(Locale) onLanguageChange;
  final VoidCallback onAuthChanged;
  
  const WelcomeScreen({super.key, required this.onLanguageChange, required this.onAuthChanged});

  String _getPersonalizedWelcomeMessage(AppLocalizations localizations) {
    final user = AuthService.user;
    if (user != null && user['firstName'] != null && user['firstName'].toString().trim().isNotEmpty) {
      return localizations.welcomePersonalized(user['firstName'].toString());
    }
    // Fallback to app title with welcome emoji if no first name
    return '🚌 ${localizations.appTitle}!';
  }

  String _getPersonalizedWelcomeDescription(AppLocalizations localizations) {
    final user = AuthService.user;
    if (user != null && user['firstName'] != null) {
      return localizations.welcomePersonalizedDescription;
    }
    // Fallback to generic localized description if no user data
    return localizations.welcomeFallbackDescription;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Logout button - clean icon
          IconButton(
            onPressed: () {
              final currentLocale = Localizations.localeOf(context);
              final newLocale = currentLocale.languageCode == 'en' 
                ? const Locale('he', '') 
                : const Locale('en', '');
              onLanguageChange(newLocale);
            },
            icon: Icon(
              Icons.language_outlined,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () async {
              await AuthService.logout();
              onAuthChanged();
            },
            icon: Icon(
              Icons.logout_rounded,
              size: 24,
            ),
            tooltip: localizations.logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Logo - without animation
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Title - minimalistic like login
              Center(
                child: Text(
                  localizations.appTitle,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle - minimalistic
              Center(
                child: Text(
                  localizations.appSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Welcome Message - clean and simple
              Text(
                _getPersonalizedWelcomeMessage(localizations),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _getPersonalizedWelcomeDescription(localizations),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}