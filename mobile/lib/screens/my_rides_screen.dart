import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/human_readable_date.dart';
import 'ride_detail_screen.dart';
import 'book_ride_screen.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _rides = [];
  bool _showAllRides = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _loadRides();
    
    // Listen for app lifecycle changes to refresh data when screen regains focus
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // Refresh rides when app resumes (user returns from ride detail or other apps)
        _loadRides();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get today's date for filtering from today onwards
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/rides/user/my-rides',
        queryParams: {
          'fromDate': todayStr, // Only fetch today's and future rides
        },
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
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    }
  }

  void _navigateToBookRide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BookRideScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          localizations.myRidesTitle,
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Refresh button - clean icon
          IconButton(
            onPressed: _loadRides,
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            tooltip: localizations.refresh,
          ),
          
          // Add button - portal color
          IconButton(
            onPressed: _navigateToBookRide,
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            tooltip: localizations.bookNewRide,
          ),
          
          // Filter toggle - clean icon
          IconButton(
            onPressed: () {
              setState(() {
                _showAllRides = !_showAllRides;
              });
            },
            icon: Icon(
              _showAllRides ? Icons.filter_list_off : Icons.filter_list,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            tooltip: _showAllRides ? localizations.filter : localizations.showAll,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF10B981),
                  strokeWidth: 2,
                ),
              )
            : _rides.isEmpty
                ? _buildEmptyState(localizations, theme)
                : _buildRidesList(localizations, theme),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredRides() {
    if (_showAllRides) {
      return _rides;
    }
    
    // Hide cancelled and completed rides by default
    return _rides.where((ride) {
      final status = ride['status']?.toString().toLowerCase() ?? '';
      return status != 'cancelled' && status != 'completed';
    }).toList();
  }

  List<Map<String, dynamic>> _getTodayRides() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _getFilteredRides().where((ride) {
      final rideDate = ride['date']?.toString() ?? '';
      return rideDate.startsWith(todayStr);
    }).toList();
  }

  List<Map<String, dynamic>> _getOtherRides() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _getFilteredRides().where((ride) {
      final rideDate = ride['date']?.toString() ?? '';
      return !rideDate.startsWith(todayStr);
    }).toList();
  }

  Widget _buildRidesList(AppLocalizations localizations, ThemeData theme) {
    final todayRides = _getTodayRides();
    final otherRides = _getOtherRides();
    
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          
          // Today's Rides Section
          if (todayRides.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                localizations.todayRides,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...todayRides.map((ride) => _buildRideCard(ride, theme, localizations, isToday: true)),
            
            if (otherRides.isNotEmpty) ...[
              const SizedBox(height: 40),
            ],
          ],
          
          // Other Rides Section
          if (otherRides.isNotEmpty) ...[
            if (todayRides.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  localizations.otherRides,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            
            if (todayRides.isNotEmpty) const SizedBox(height: 16),
            
            ...otherRides.map((ride) => _buildRideCard(ride, theme, localizations)),
          ],
          
          // Show message when no rides match filter
          if (todayRides.isEmpty && otherRides.isEmpty && !_showAllRides) ...[
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Text(
                    localizations.noActiveRidesFound,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    localizations.tapShowAllForCompleted,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          
          Text(
            localizations.myRidesEmpty,
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            localizations.myRidesEmptyDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadRides,
              child: Text(
                localizations.refresh,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, ThemeData theme, AppLocalizations localizations, {bool isToday = false}) {
    final status = ride['status'] ?? 'unknown';
    final startTime = ride['startTime'] ?? '';
    final date = ride['date'] ?? '';
    final routeName = ride['route']?['name'] ?? 'Unknown Route';
    
    // Format date and time display
    String dateTimeDisplay = '';
    if (date.isNotEmpty) {
      dateTimeDisplay = _formatDateTime(startTime, startDate: date);
    }
    
    // Status color and translated text
    Color statusColor = const Color(0xFF6B7280);
    String statusText = status;
    
    switch (status.toLowerCase()) {
      case 'in_progress':
        statusColor = const Color(0xFF10B981);
        statusText = localizations.rideStatusActive;
        break;
      case 'completed':
        statusColor = const Color(0xFF6B7280);
        statusText = localizations.rideStatusCompleted;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFD32F2F);
        statusText = localizations.rideStatusCancelled;
        break;
      case 'scheduled':
        statusColor = const Color(0xFF10B981);
        statusText = localizations.rideStatusScheduled;
        break;
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFF0FDF4) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RideDetailScreen(ride: ride),
              ),
            );
          },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route name
            Text(
              routeName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Date and time
            if (date.isNotEmpty) ...[
              Row(
                children: [
                  HumanReadableDate(
                    dateString: date,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (startTime.isNotEmpty) ...[
                    Text(
                      ' - ${_formatTime(startTime)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
            ],
            
            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.outline,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  String _formatTime(String timeString) {
    try {
      if (timeString.isEmpty) return '';
      final timeDateTime = DateTime.parse(timeString);
      return '${timeDateTime.hour.toString().padLeft(2, '0')}:${timeDateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  String _formatDateTime(String timeString, {required String startDate}) {
    try {
      final dateDateTime = DateTime.parse(startDate);
      final rideDate = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day);
      final date = '${rideDate.day}/${rideDate.month}/${rideDate.year}';

      if (timeString.isNotEmpty) {
        final time = _formatTime(timeString);
        return '$date - $time';
      } else {
        return date;
      }
    } catch (e) {
      return startDate; // Return original if parsing fails
    }
  }
}