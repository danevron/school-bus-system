import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'welcome_screen.dart';
import 'my_rides_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  final VoidCallback onAuthChanged;

  const MainNavigationScreen({
    super.key,
    required this.onLanguageChange,
    required this.onAuthChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WelcomeScreen(
        onLanguageChange: widget.onLanguageChange,
        onAuthChanged: widget.onAuthChanged,
      ),
      const MyRidesScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: localizations.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bus_outlined),
            selectedIcon: const Icon(Icons.directions_bus),
            label: localizations.myRides,
          ),
        ],
      ),
    );
  }
}