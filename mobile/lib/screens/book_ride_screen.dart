import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/human_readable_date.dart';
import '../utils/formatting_utils.dart';

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
  final Map<String, String?> _selectedPickupStops = {}; // rideId -> stopId
  final Map<String, String?> _selectedDropoffStops = {}; // rideId -> stopId
  
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

      final guestsResponse = await AuthService.authenticatedRequest('GET', '/api/auth/my-guests');

      if (guestsResponse.statusCode == 200) {
        final responseData = json.decode(guestsResponse.body);
        final guests = responseData['data']['guests'] as List? ?? [];
        
        // Add guests to available passengers
        for (final guest in guests) {
          final guestMap = guest as Map<String, dynamic>;
          _availablePassengers.add({
            '_id': guestMap['_id'],
            'firstName': guestMap['firstName'] ?? 'Guest',
            'lastName': guestMap['lastName'] ?? '',
            'role': guestMap['role'] ?? 'student',
            'isCurrentUser': false,
            'isGuest': true,
          });
        }
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
          'isGuest': false,
        }
      ];
    }

    // Default selection is current user
    if (_availablePassengers.isNotEmpty) {
      _selectedPassengerId = _availablePassengers.first['_id'];
    }
  }

  Future<void> _refreshPassengers() async {
    await _loadAvailablePassengers();
    setState(() {});
  }

  void _showAddGuestDialog() async {
    await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddGuestModal(),
    ).then((guestCreated) {
      if (guestCreated == true) {
        _refreshPassengers();
      }
    });
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
    
    // Show booking confirmation modal
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BookingConfirmationModal(
        ride: ride,
        selectedPassengerId: _selectedPassengerId,
        pickupStopId: pickupStopId,
        dropoffStopId: dropoffStopId,
        availablePassengers: _availablePassengers,
      ),
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
            _buildPassengerSelection(theme, colorScheme, localizations),
            
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
          Text(
            localizations.bookRideFor,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._availablePassengers.map((passenger) {
                final isSelected = passenger['_id'] == _selectedPassengerId;
                String displayName;
                if (passenger['isCurrentUser']) {
                  displayName = localizations.mePassenger(passenger['firstName']);
                } else if (passenger['isGuest'] == true) {
                  displayName = '${passenger['firstName']} ${passenger['lastName']} (${localizations.guest})';
                } else {
                  displayName = '${passenger['firstName']} ${passenger['lastName']}';
                }
                
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
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.primary.withOpacity(0.1),
                  side: BorderSide(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }).toList(),
              // Add Guest button
              ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(localizations.addGuest),
                  ],
                ),
                onPressed: _showAddGuestDialog,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
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
              color: colorScheme.onSurface,
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
    final driver = ride['driver'] ?? {};
    final availableSeats = ride['availableSeats'] ?? 0;
    final maxCapacity = ride['maxCapacity'] ?? 0;

    return InkWell(
      onTap: () => _showRideBookingModal(ride),
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
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
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (route['description']?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        route['description'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                localizations.seatsAvailable(availableSeats, maxCapacity),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: availableSeats > 5 ? colorScheme.primary : colorScheme.error,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Date and time
          Row(
            children: [
              HumanReadableDate(
                dateString: ride['date'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                ' - ${FormattingUtils.formatTime(ride['startTime'] ?? '')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          if (availableSeats == 0) ...[
            Text(
              localizations.waitingListNotice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            )
          ],
        ],
        ),
      ),
    );
  }

  Future<void> _showRideBookingModal(Map<String, dynamic> ride) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RideBookingModal(
        ride: ride,
        onBook: (pickupStopId, dropoffStopId) async {
          Navigator.of(context).pop();
          await _bookRideWithStops(ride, pickupStopId, dropoffStopId);
        },
      ),
    );
  }

  Future<void> _bookRideWithStops(Map<String, dynamic> ride, String? pickupStopId, String? dropoffStopId) async {
    if (pickupStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectPickupStop),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (dropoffStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectDropoffStop),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Set the selected stops for this ride temporarily to use existing booking logic
    final rideId = ride['_id'];
    setState(() {
      _selectedPickupStops[rideId] = pickupStopId;
      _selectedDropoffStops[rideId] = dropoffStopId;
    });

    await _bookRide(ride);
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
                                  ),
                                ),
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
                          style: theme.textTheme.bodyMedium,
                        ),
                ),
                Icon(
                  hasSelection ? Icons.edit : Icons.arrow_forward_ios,
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

class _RideBookingModal extends StatefulWidget {
  final Map<String, dynamic> ride;
  final Function(String?, String?) onBook;

  const _RideBookingModal({
    required this.ride,
    required this.onBook,
  });

  @override
  State<_RideBookingModal> createState() => _RideBookingModalState();
}

class _RideBookingModalState extends State<_RideBookingModal> {
  String? _selectedPickupStopId;
  String? _selectedDropoffStopId;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ride = widget.ride;
    final route = ride['route'] ?? {};
    final stops = ride['stops'] as List? ?? [];
    final availableSeats = ride['availableSeats'] ?? 0;
    
    final availableDropoffStops = stops.where((stop) => stop['type'] == 'dropoff');
    final onlyOneAvailableDroppffStop = availableDropoffStops.length == 1;
    
    final availablePickupStops = stops.where((stop) => stop['type'] == 'pickup');
    final onlyOneAvailablePickupStop = availablePickupStops.length == 1;

    if (onlyOneAvailableDroppffStop) {
      _selectedDropoffStopId = availableDropoffStops.first['stopId'];
    }

    if (onlyOneAvailablePickupStop) {
      _selectedPickupStopId = availablePickupStops.first['stopId'];
    }

    // Find selected stop details
    Map<String, dynamic>? pickupStop;
    Map<String, dynamic>? dropoffStop;
    
    if (_selectedPickupStopId != null) {
      try {
        pickupStop = stops.cast<Map<String, dynamic>>().firstWhere(
          (stop) => stop['stopId'] == _selectedPickupStopId,
        );
      } catch (e) {
        pickupStop = null;
      }
    }
    
    if (_selectedDropoffStopId != null) {
      try {
        dropoffStop = stops.cast<Map<String, dynamic>>().firstWhere(
          (stop) => stop['stopId'] == _selectedDropoffStopId,
        );
      } catch (e) {
        dropoffStop = null;
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header with close button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route['name'] ?? localizations.unknownRoute,
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
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ride info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              HumanReadableDate(
                                dateString: ride['date'] ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                ' - ${FormattingUtils.formatTime(ride['startTime'] ?? '')}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            availableSeats == 0 ? localizations.fullyBooked : '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: availableSeats > 5 ? colorScheme.primary : colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            localizations.seatsAvailable(availableSeats, ride['maxCapacity'] ?? 0),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: availableSeats > 5 ? colorScheme.primary : colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Stop selection
                    Text(
                      localizations.selectStops,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pickup stop
                    _buildStopSelector(
                      label: localizations.pickup,
                      showOnMapLabel: localizations.openInMaps,
                      selectedStop: pickupStop,
                      hint: localizations.choosePickupStop,
                      onTap: onlyOneAvailablePickupStop ? () => null : () => _showStopSelection('pickup'),
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dropoff stop
                    _buildStopSelector(
                      label: localizations.dropoff,
                      showOnMapLabel: localizations.openInMaps,
                      selectedStop: dropoffStop,
                      hint: localizations.chooseDropoffStop,
                      onTap: onlyOneAvailableDroppffStop ? () => null : () => _showStopSelection('dropoff'),
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          
          // Book button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ElevatedButton.icon(
              icon: Icon(availableSeats == 0 ? Icons.schedule : Icons.check_circle_outline),
              onPressed: (_selectedPickupStopId != null && _selectedDropoffStopId != null)
                  ? () => widget.onBook(_selectedPickupStopId, _selectedDropoffStopId)
                  : null,
              style: availableSeats == 0 
                  ? ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    )
                  : null,
              label: Text(availableSeats == 0 
                  ? localizations.bookingStatusWaitingList 
                  : localizations.bookThisRide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopSelector({
    required String label,
    required String showOnMapLabel,
    required Map<String, dynamic>? selectedStop,
    required String hint,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedStop?.isNotEmpty == true
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedStop!['name'] ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (selectedStop!['address']?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _openInMaps(selectedStop!['address']),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 17,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      showOnMapLabel,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          hint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showStopSelection(String type) async {
    final stops = widget.ride['stops'] as List? ?? [];
    final route = widget.ride['route'] ?? {};
    
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StopSelectionModal(
        stops: stops.cast<Map<String, dynamic>>(),
        selectionType: type,
        currentSelection: type == 'pickup' ? _selectedPickupStopId : _selectedDropoffStopId,
        excludeStopId: type == 'dropoff' ? _selectedPickupStopId : null,
        rideRoute: route['name'] ?? 'Unknown Route',
        isDropoff: type == 'dropoff',
      ),
    );

    if (result != null) {
      setState(() {
        if (type == 'pickup') {
          _selectedPickupStopId = result;
          // Reset dropoff if same as pickup
          if (_selectedDropoffStopId == result) {
            _selectedDropoffStopId = null;
          }
        } else {
          _selectedDropoffStopId = result;
        }
      });
    }
  }
  Future<void> _openInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse('maps:?q=$encodedAddress');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
    Navigator.of(context).pop(_selectedStopId);
  }

  Future<void> _openInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse('maps:?q=$encodedAddress');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
                        GestureDetector(
                          onTap: () => _openInMaps(address),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations.openInMaps,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
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
                          size: 20,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
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

class _AddGuestModal extends StatefulWidget {
  const _AddGuestModal();

  @override
  State<_AddGuestModal> createState() => _AddGuestModalState();
}

class _AddGuestModalState extends State<_AddGuestModal> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createGuest() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    
    try {
      setState(() => _isLoading = true);
      
      final requestBody = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
      };
      
      final response = await AuthService.authenticatedRequest(
        'POST', 
        '/api/auth/guests',
        body: requestBody,
      );
      
      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate successful creation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.guestCreatedSuccessfully),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        throw Exception('Failed to create guest');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToCreateGuest),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            child: Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.addGuest,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: localizations.firstName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.pleaseEnterFirstName;
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: localizations.lastName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.pleaseEnterLastName;
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: '${localizations.phone} (${localizations.optional})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              onPressed: _isLoading ? null : _createGuest,
              label: Text(
                localizations.add,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingConfirmationModal extends StatelessWidget {
  final Map<String, dynamic> ride;
  final String? selectedPassengerId;
  final String? pickupStopId;
  final String? dropoffStopId;
  final List<Map<String, dynamic>> availablePassengers;

  const _BookingConfirmationModal({
    required this.ride,
    required this.selectedPassengerId,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.availablePassengers,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final availableSeats = ride['availableSeats'] ?? 0;

    final selectedPassenger = availablePassengers.firstWhere(
      (p) => p['_id'] == selectedPassengerId,
    );
    
    final pickupStop = (ride['stops'] as List).firstWhere(
      (stop) => stop['stopId'] == pickupStopId,
    );
    
    final dropoffStop = (ride['stops'] as List).firstWhere(
      (stop) => stop['stopId'] == dropoffStopId,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.confirmBooking,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Ride Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['route']['name'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            HumanReadableDate(
                              dateString: ride['date'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              FormattingUtils.formatTime(ride['startTime'] ?? ''),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Passenger Info
                  Text(
                    localizations.passenger,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${selectedPassenger['firstName']} ${selectedPassenger['lastName']}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pickup Stop
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.pickup,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              pickupStop['name'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dropoff Stop
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.dropoff,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              dropoffStop['name'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
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
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: availableSeats == 0 ? colorScheme.secondary : null,
                      foregroundColor: availableSeats == 0 ? colorScheme.onSecondary : null,
                    ),
                    child: Text(
                      availableSeats == 0 
                          ? localizations.bookingStatusWaitingList 
                          : localizations.bookThisRide,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      localizations.cancel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}