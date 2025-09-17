import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableRides = [];
  List<Map<String, dynamic>> _availablePassengers = [];
  String? _selectedPassengerId;
  Map<String, String?> _selectedPickupStops = {}; // rideId -> stopId
  Map<String, String?> _selectedDropoffStops = {}; // rideId -> stopId
  Set<String> _expandedRides = {}; // Track which rides are expanded
  
  bool get _hasChildren => _availablePassengers.length > 1;

  @override
  void initState() {
    super.initState();
    _loadAvailablePassengers();
    _loadAvailableRides();
  }

  Future<void> _loadAvailablePassengers() async {
    try {
      // Get current user info
      final currentUser = AuthService.user;
      _availablePassengers = [
        {
          '_id': currentUser?['_id'] ?? currentUser?['id'],
          'firstName': currentUser?['firstName'] ?? 'User',
          'lastName': currentUser?['lastName'] ?? '',
          'role': currentUser?['role'] ?? 'parent',
          'isCurrentUser': true,
        }
      ];

      // Load children from profile endpoint for any user type
      final response = await AuthService.authenticatedRequest('GET', '/api/auth/profile');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final user = responseData['user'] as Map<String, dynamic>?;
        final children = user?['children'] as List? ?? [];
        
        // Add children to available passengers
        for (final child in children) {
          final childMap = child as Map<String, dynamic>;
          _availablePassengers.add({
            '_id': childMap['_id'],
            'firstName': childMap['firstName'] ?? 'Child',
            'lastName': childMap['lastName'] ?? '',
            'role': childMap['role'] ?? 'student',
            'isCurrentUser': false,
          });
        }
      }

      // Default selection is current user
      if (_availablePassengers.isNotEmpty) {
        _selectedPassengerId = _availablePassengers.last['_id'];
      }
    } catch (e) {
      // Fallback to just current user if API call fails
      final currentUser = AuthService.user;
      _availablePassengers = [
        {
          '_id': currentUser?['_id'] ?? currentUser?['id'],
          'firstName': currentUser?['firstName'] ?? 'User',
          'lastName': currentUser?['lastName'] ?? '',
          'role': currentUser?['role'] ?? 'parent',
          'isCurrentUser': true,
        }
      ];
      if (_availablePassengers.isNotEmpty) {
        _selectedPassengerId = _availablePassengers.first['_id'];
      }
    }
  }

  Future<void> _loadAvailableRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get today's date for filtering
      final today = DateTime.now().toIso8601String().split('T')[0];
      final oneWeekFromNow = DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0];
      
      // Make API call to get available rides
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/rides',
        queryParams: {'fromDate': today, 'toDate': oneWeekFromNow, 'status': 'scheduled'} // Fetch rides within the next week
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final dataObject = responseData['data'] as Map<String, dynamic>? ?? {};
        final rides = dataObject['rides'] as List? ?? [];
        
        // Transform API response to match our UI structure
        final transformedRides = rides.map<Map<String, dynamic>>((ride) {
          final rideMap = ride as Map<String, dynamic>;
          final route = rideMap['route'] as Map<String, dynamic>? ?? {};
          final stops = route['stops'] as List? ?? [];
          
          return {
            '_id': rideMap['_id'],
            'route': {
              'name': route['name'] ?? 'Unknown Route',
              'description': route['description'] ?? '',
            },
            'date': rideMap['date'],
            'startTime': rideMap['startTime'],
            'vehicle': rideMap['vehicle'] ?? {},
            'driver': rideMap['driver'] ?? {},
            'availableSeats': rideMap['availableSeats'] ?? 0,
            'maxCapacity': rideMap['maxCapacity'] ?? 0,
            // Transform stops to match our UI structure
            'stops': stops.map((stop) {
              final stopMap = stop as Map<String, dynamic>;
              return {
                'stopId': stopMap['_id'] ?? stopMap['stopId'],
                'name': stopMap['name'] ?? 'Unknown Stop',
                'address': stopMap['address'] ?? '',
                'type': stopMap['type'], // Preserve the type property
                'estimatedTime': _formatEstimatedTime(stopMap['estimatedArrivalTime']),
              };
            }).toList(),
          };
        }).toList();
        
        setState(() {
          _availableRides = transformedRides;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load rides: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.networkError}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    if (_selectedPassengerId == null) return;

    final localizations = AppLocalizations.of(context)!;
    final rideId = ride['_id'];
    final pickupStopId = _selectedPickupStops[rideId];
    final dropoffStopId = _selectedDropoffStops[rideId];

    if (pickupStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseSelectPickupStop),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (dropoffStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseSelectDropoffStop),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show booking confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final selectedPassenger = _availablePassengers.firstWhere(
          (p) => p['_id'] == _selectedPassengerId,
        );
        
        final pickupStop = (ride['stops'] as List).firstWhere(
          (stop) => stop['stopId'] == pickupStopId,
        );
        
        final dropoffStop = (ride['stops'] as List).firstWhere(
          (stop) => stop['stopId'] == dropoffStopId,
        );
        
        final dialogTheme = Theme.of(context);
        final dialogColorScheme = dialogTheme.colorScheme;
        
        return AlertDialog(
          title: Text(
            localizations.confirmBooking,
            style: dialogTheme.textTheme.headlineMedium?.copyWith(
              color: dialogColorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.ride}: ${ride['route']['name']}',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.passenger}: ${selectedPassenger['firstName']} ${selectedPassenger['lastName']}',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.date}: ${_formatDate(ride['date'])}',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.time}: ${_formatTime(ride['startTime'] ?? '')}',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${localizations.pickup}: ${pickupStop['name']}',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.dropoff}: ${dropoffStop['name']}',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: dialogColorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                localizations.cancel,
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: dialogColorScheme.primary,
                foregroundColor: dialogColorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                localizations.bookThisRide,
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogColorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Make API call to book the ride
        final response = await AuthService.authenticatedRequest(
          'POST',
          '/api/bookings',
          body: {
            'rideId': rideId,
            'passengerId': _selectedPassengerId,
            'pickupStop': {
              'stopId': pickupStopId
            },
            'dropoffStop': {
              'stopId': dropoffStopId
            },
          },
        );
        
        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.rideBookedSuccessfully),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate back to My Rides screen
            Navigator.of(context).pop();
          }
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to book ride');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.failedToBookRide}: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(String dateString) {
    final localizations = AppLocalizations.of(context)!;
    if (dateString.isEmpty) return localizations.tbd;
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.isNotEmpty ? dateString : localizations.tbd;
    }
  }

  String _formatTime(String timeString) {
    final localizations = AppLocalizations.of(context)!;
    if (timeString.isEmpty) return localizations.tbd;
    
    try {
      final time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString.isNotEmpty ? timeString : localizations.tbd;
    }
  }
  
  String _formatEstimatedTime(dynamic estimatedTime) {
    if (estimatedTime == null) return '';
    
    try {
      if (estimatedTime is String) {
        // If it's already a time string like "07:15", return as is
        if (RegExp(r'^\d{2}:\d{2}$').hasMatch(estimatedTime)) {
          return estimatedTime;
        }
        // If it's a full datetime, parse and format
        final time = DateTime.parse(estimatedTime);
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      return estimatedTime.toString();
    } catch (e) {
      return estimatedTime.toString();
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.bookNewRide,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Passenger Selection (only when user has children)
            if (_hasChildren) _buildPassengerSelection(theme, colorScheme, localizations),
            
            // Available Rides List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableRides.isEmpty
                      ? _buildEmptyState(theme, colorScheme, localizations)
                      : _buildRidesList(theme, colorScheme, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSelection(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.bookRideFor,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePassengers.map((passenger) {
              final isSelected = passenger['_id'] == _selectedPassengerId;
              final displayName = passenger['isCurrentUser']
                  ? localizations.mePassenger(passenger['firstName'])
                  : '${passenger['firstName']} ${passenger['lastName']}';
              
              return ChoiceChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPassengerId = passenger['_id'];
                    });
                  }
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF10B981).withOpacity(0.1),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
          child: Text(
            localizations.availableRidesCount(_availableRides.length),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _availableRides.length,
            itemBuilder: (context, index) {
              final ride = _availableRides[index];
              return _buildRideCard(ride, theme, colorScheme, localizations);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final route = ride['route'] ?? {};
    final vehicle = ride['vehicle'] ?? {};
    final driver = ride['driver'] ?? {};
    final availableSeats = ride['availableSeats'] ?? 0;
    final maxCapacity = ride['maxCapacity'] ?? 0;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route name and available seats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['name'] ?? localizations.unknownRoute,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (route['description']?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        route['description'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: availableSeats > 5 ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  localizations.seatsAvailable(availableSeats, maxCapacity),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: availableSeats > 5 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Date and time
          Text(
            '${_formatDate(ride['date'] ?? '')} at ${_formatTime(ride['startTime'] ?? '')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Vehicle and driver
          Text(
            '${vehicle['licensePlate']} - Driver: ${driver['firstName']} ${driver['lastName']}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Expand/Collapse button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  final rideId = ride['_id'];
                  if (_expandedRides.contains(rideId)) {
                    _expandedRides.remove(rideId);
                  } else {
                    _expandedRides.add(rideId);
                  }
                });
              },
              style: OutlinedButton.styleFrom(
                elevation: 0,
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(
                _expandedRides.contains(ride['_id']) ? localizations.hideBookingOptions : localizations.showBookingOptions,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Stop selection section (only when expanded)
          if (_expandedRides.contains(ride['_id'])) ...[
            const SizedBox(height: 16),
            _buildStopSelection(ride, theme, colorScheme, localizations),
            const SizedBox(height: 16),
            
            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: availableSeats > 0 ? () => _bookRide(ride) : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF6B7280),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  availableSeats > 0 ? localizations.bookThisRide : localizations.fullyBooked,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopSelection(Map<String, dynamic> ride, ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final rideId = ride['_id'];
    final stops = ride['stops'] as List? ?? [];
    final pickupStopId = _selectedPickupStops[rideId];
    final dropoffStopId = _selectedDropoffStops[rideId];
    
    // Find selected stop details
    Map<String, dynamic>? pickupStop;
    Map<String, dynamic>? dropoffStop;
    
    if (pickupStopId != null) {
      try {
        pickupStop = stops.cast<Map<String, dynamic>>().firstWhere((stop) => stop['stopId'] == pickupStopId);
      } catch (e) {
        pickupStop = null;
      }
    }
    
    if (dropoffStopId != null) {
      try {
        dropoffStop = stops.cast<Map<String, dynamic>>().firstWhere((stop) => stop['stopId'] == dropoffStopId);
      } catch (e) {
        dropoffStop = null;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectStops,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // Pickup stop selection
          _buildStopSelectionTile(
            icon: Icons.location_on,
            iconColor: Colors.green,
            label: localizations.pickup,
            selectedStop: pickupStop,
            hint: localizations.choosePickupStop,
            onTap: () => _showStopSelectionModal(ride, 'pickup'),
            theme: theme,
            colorScheme: colorScheme,
            localizations: localizations,
            isRequired: true,
          ),
          
          const SizedBox(height: 12),
          
          // Dropoff stop selection
          _buildStopSelectionTile(
            icon: Icons.location_off,
            iconColor: Colors.red,
            label: localizations.dropoff,
            selectedStop: dropoffStop,
            hint: localizations.chooseDropoffStop,
            onTap: () => _showStopSelectionModal(ride, 'dropoff'),
            theme: theme,
            colorScheme: colorScheme,
            localizations: localizations,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStopSelectionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Map<String, dynamic>? selectedStop,
    required String hint,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AppLocalizations localizations,
    required bool isRequired,
  }) {
    final hasSelection = selectedStop != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasSelection 
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
              color: hasSelection 
                  ? colorScheme.primary.withOpacity(0.05)
                  : colorScheme.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: hasSelection
                      ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedStop!['name'] ?? localizations.unknownStop,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (selectedStop['address']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedStop['address'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (selectedStop['estimatedTime']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      localizations.eta(selectedStop['estimatedTime']),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                      : Text(
                          hint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                Icon(
                  hasSelection ? Icons.edit : Icons.arrow_forward_ios,
                  color: hasSelection 
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showStopSelectionModal(Map<String, dynamic> ride, String selectionType) async {
    final localizations = AppLocalizations.of(context)!;
    final rideId = ride['_id'];
    final stops = ride['stops'] as List? ?? [];
    final currentSelection = selectionType == 'pickup' 
        ? _selectedPickupStops[rideId]
        : _selectedDropoffStops[rideId];
    final excludeStopId = selectionType == 'dropoff' 
        ? _selectedPickupStops[rideId]
        : null;
    final isDropoff = selectionType == 'dropoff';
    
    final selectedStopId = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StopSelectionModal(
        stops: stops.cast<Map<String, dynamic>>(),
        selectionType: selectionType,
        currentSelection: currentSelection,
        excludeStopId: excludeStopId,
        rideRoute: ride['route']?['name'] ?? localizations.unknownRoute,
        isDropoff: isDropoff,
      ),
    );

    if (selectedStopId != null) {
      setState(() {
        if (selectionType == 'pickup') {
          _selectedPickupStops[rideId] = selectedStopId;
          // Reset dropoff if it's the same as new pickup
          if (_selectedDropoffStops[rideId] == selectedStopId) {
            _selectedDropoffStops[rideId] = null;
          }
        } else {
          _selectedDropoffStops[rideId] = selectedStopId;
        }
      });
    }
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noAvailableRides,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.checkBackLaterRides,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> stops;
  final String selectionType;
  final String? currentSelection;
  final String? excludeStopId;
  final String rideRoute;
  final bool isDropoff;

  const _StopSelectionModal({
    required this.stops,
    required this.selectionType,
    this.currentSelection,
    this.excludeStopId,
    required this.rideRoute,
    required this.isDropoff,
  });

  @override
  State<_StopSelectionModal> createState() => _StopSelectionModalState();
}

class _StopSelectionModalState extends State<_StopSelectionModal> {
  String? _selectedStopId;
  List<Map<String, dynamic>> _filteredStops = [];

  @override
  void initState() {
    super.initState();
    _selectedStopId = widget.currentSelection;
    _filterStops();
  }

  void _filterStops() {
    _filteredStops = widget.stops.where((stop) {
      // Exclude the specified stop (usually pickup when selecting dropoff)
      if (widget.excludeStopId != null && stop['stopId'] == widget.excludeStopId) {
        return false;
      }
      
      // Filter by stop type: only show pickup stops for pickup selection and dropoff stops for dropoff selection
      final stopType = stop['type'] as String?;
      if (widget.selectionType == 'pickup') {
        return stopType == 'pickup';
      } else if (widget.selectionType == 'dropoff') {
        return stopType == 'dropoff';
      }
      
      // If no specific type requirement, show all stops (fallback)
      return true;
    }).toList();
  }

  void _selectStop(String? stopId) {
    setState(() {
      _selectedStopId = stopId;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedStopId);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.rideRoute,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      widget.isDropoff ? Icons.location_off : Icons.location_on,
                      color: widget.isDropoff ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isDropoff 
                        ? localizations.chooseDropoffLocationHint
                        : localizations.choosePickupLocationHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stop selection list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
                  child: Text(
                    localizations.availableStopsCount(_filteredStops.length),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredStops.length,
                    itemBuilder: (context, index) {
                      final stop = _filteredStops[index];
                      return _buildStopTile(
                        stop['stopId'],
                        stop['name'] ?? localizations.unknownStop,
                        stop['address'] ?? '',
                        stop['estimatedTime'],
                        theme,
                        colorScheme,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Confirm button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            child: ElevatedButton(
              onPressed: _selectedStopId != null
                  ? _confirmSelection
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                localizations.confirmSelection,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopTile(
    String? stopId,
    String name,
    String address,
    String? estimatedTime,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final isSelected = _selectedStopId == stopId;
    
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.05) : colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectStop(stopId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (estimatedTime?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            localizations.eta(estimatedTime ?? ''),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}