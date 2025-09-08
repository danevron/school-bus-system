import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'ride_detail_screen.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _rides = [];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/rides/driver/my-rides',
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final ridesData = responseData['data']?['rides'] as List? ?? [];

        ridesData.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
          return dateA.compareTo(dateB); // Oldest first
        });
        
        setState(() {
          _rides = ridesData.map((ride) => ride as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load rides');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.networkError}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
        title: Row(
          children: [
            Icon(
              Icons.directions_bus,
              size: 28,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              localizations.myRidesTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false, // Remove back button since we use bottom nav
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _rides.isEmpty
                ? _buildEmptyState(localizations, theme, colorScheme)
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: _rides.length,
                      itemBuilder: (context, index) {
                        final ride = _rides[index];
                        return _buildRideCard(ride, theme, colorScheme, localizations);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              localizations.myRidesEmpty,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              localizations.myRidesEmptyDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            FilledButton.icon(
              onPressed: _loadRides,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.refresh),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final status = ride['status'] ?? 'unknown';
    final startTime = ride['startTime'] ?? '';
    final date = ride['date'] ?? '';
    final routeName = ride['route']?['name'] ?? 'Unknown Route';
    
    // Format date and time display
    String dateTimeDisplay = '';
    if (date.isNotEmpty) {
      dateTimeDisplay = _formatDateTime(startTime, startDate: date);
    }
    
    // Status color, icon and translated text
    Color statusColor = colorScheme.onSurface;
    IconData statusIcon = Icons.directions_bus;
    String statusText = status;
    
    switch (status.toLowerCase()) {
      case 'in_progress':
        statusColor = Colors.green;
        statusIcon = Icons.play_circle;
        statusText = localizations.rideStatusActive;
        break;
      case 'completed':
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.check_circle;
        statusText = localizations.rideStatusCompleted;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = localizations.rideStatusCancelled;
        break;
      case 'scheduled':
        statusColor = colorScheme.primary;
        statusIcon = Icons.schedule;
        statusText = localizations.rideStatusScheduled;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          statusIcon,
          color: statusColor,
          size: 32,
        ),
        title: Text(
          routeName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dateTimeDisplay.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                dateTimeDisplay,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RideDetailScreen(ride: ride),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(String timeString, {required String startDate}) {
    try {
      final dateDateTime = DateTime.parse(startDate);
      final rideDate = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day);
      final date = '${rideDate.day}/${rideDate.month}/${rideDate.year}';

      if (timeString.isNotEmpty) {
        final timeDateTime = DateTime.parse(timeString);
        final time = '${timeDateTime.hour.toString().padLeft(2, '0')}:${timeDateTime.minute.toString().padLeft(2, '0')}';
        return '$date - $time';
      } else {
        return date;
      }
    } catch (e) {
      return startDate; // Return original if parsing fails
    }
  }
}