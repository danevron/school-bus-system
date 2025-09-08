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
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<Locale>(
            icon: Icon(
              Icons.language,
              color: colorScheme.primary,
            ),
            onSelected: onLanguageChange,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<Locale>(
                value: const Locale('en', ''),
                child: Row(
                  children: [
                    const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(localizations.english),
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('he', ''),
                child: Row(
                  children: [
                    const Text('🇮🇱', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(localizations.hebrew),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: colorScheme.primary,
            ),
            onPressed: () async {
              await AuthService.logout();
              onAuthChanged();
            },
            tooltip: localizations.logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Centered content
              Column(
                children: [
                  // School Bus Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      size: 80,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App Title
                  Text(
                    localizations.appTitle,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Subtitle
                  Text(
                    localizations.appSubtitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome Message
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getPersonalizedWelcomeMessage(localizations),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 15),
                        
                        Text(
                          _getPersonalizedWelcomeDescription(localizations),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}