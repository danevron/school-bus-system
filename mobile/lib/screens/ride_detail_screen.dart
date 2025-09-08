import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class RideDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDetailScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  bool _isLoading = false;
  bool _isStartingRide = false;
  bool _isEndingRide = false;
  bool _isSharingLocation = false;
  List<Map<String, dynamic>> _bookings = [];
  late Map<String, dynamic> _currentRide;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _currentRide = Map<String, dynamic>.from(widget.ride);
    _loadBookings();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/bookings/ride/${_currentRide['_id']}',
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final bookingsData = responseData['data']?['bookings'] as List? ?? [];
        
        setState(() {
          _bookings = bookingsData.map((booking) {
            // Transform the API response to match our expected format
            return {
              '_id': booking['_id'],
              'passenger': booking['passenger'],
              'status': booking['status'],
              'pickupStop': booking['pickupStop']?['name'] ?? '',
              'dropoffStop': booking['dropoffStop']?['name'] ?? '',
              'pickupAddress': booking['pickupStop']?['address'] ?? '',
              'dropoffAddress': booking['dropoffStop']?['address'] ?? '',
              'notes': booking['notes'] ?? '',
              'bookingDate': booking['bookingDate'],
            } as Map<String, dynamic>;
          }).toList();
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load bookings');
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

  Future<void> _startRide() async {
    setState(() {
      _isStartingRide = true;
    });

    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/api/rides/${_currentRide['_id']}/start',
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _currentRide['status'] = 'in_progress';
          _currentRide['actualStartTime'] = DateTime.now().toIso8601String();
          _isStartingRide = false;
        });
        
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.rideStartedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to start ride');
      }
    } catch (e) {
      setState(() {
        _isStartingRide = false;
      });
      
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.failedToStartRide}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _endRide() async {
    setState(() {
      _isEndingRide = true;
    });

    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/api/rides/${_currentRide['_id']}/end',
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _currentRide['status'] = 'completed';
          _currentRide['actualEndTime'] = DateTime.now().toIso8601String();
          _isEndingRide = false;
        });
        
        // Stop location sharing when ride ends
        _stopLocationSharing();
        
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.rideEndedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to end ride');
      }
    } catch (e) {
      setState(() {
        _isEndingRide = false;
      });
      
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.failedToEndRide}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleLocationSharing() async {
    if (_isSharingLocation) {
      _stopLocationSharing();
    } else {
      await _startLocationSharing();
    }
  }

  Future<void> _startLocationSharing() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.locationPermissionRequired),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.locationPermissionRequired),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _isSharingLocation = true;
      });

      // Send location every 10 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await _sendCurrentLocation();
      });

      // Send initial location
      await _sendCurrentLocation();

    } catch (e) {
      setState(() {
        _isSharingLocation = false;
      });
    }
  }

  void _stopLocationSharing() {
    setState(() {
      _isSharingLocation = false;
    });
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _sendCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      // Only include optional fields if they have valid values
      if (position.speed >= 0) {
        locationData['speed'] = position.speed;
      }
      
      if (position.heading >= 0 && position.heading <= 360) {
        locationData['heading'] = position.heading;
      }
      
      if (position.accuracy > 0) {
        locationData['accuracy'] = position.accuracy;
      }

      await AuthService.authenticatedRequest(
        'POST',
        '/api/rides/${_currentRide['_id']}/location',
        body: locationData,
      );

    } catch (e) {
      print('Error sending location: $e');
      // Don't show error to user for individual location updates to avoid spam
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      String endpoint;
      String successMessage;
      
      // Handle check-in and dropoff actions
      switch (newStatus) {
        case 'checked_in':
          endpoint = '/api/bookings/$bookingId/checkin';
          successMessage = AppLocalizations.of(context)!.passengerCheckedInSuccessfully;
          break;
        case 'completed':
          endpoint = '/api/bookings/$bookingId/dropoff';
          successMessage = AppLocalizations.of(context)!.passengerDroppedOffSuccessfully;
          break;
        default:
          throw Exception('Unsupported action: $newStatus');
      }

      final response = await AuthService.authenticatedRequest(
        'POST',
        endpoint,
      );
      
      if (response.statusCode == 200) {
        // Update local state on successful API call
        setState(() {
          final bookingIndex = _bookings.indexWhere((b) => b['_id'] == bookingId);
          if (bookingIndex >= 0) {
            _bookings[bookingIndex]['status'] = newStatus;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update passenger status');
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.failedToUpdateBooking}: ${e.toString()}'),
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _currentRide['route']?['name'] ?? localizations.rideDetails,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ride Status Header
            _buildRideHeader(theme, colorScheme, localizations),
            
            // Start Ride Button (only for scheduled rides)
            if (_currentRide['status'] == 'scheduled')
              _buildStartRideButton(theme, colorScheme, localizations),
            
            // End Ride Button (only for in-progress rides)
            if (_currentRide['status'] == 'in_progress')
              _buildEndRideButton(theme, colorScheme, localizations),
            
            // Location Sharing Button (only for in-progress rides)
            if (_currentRide['status'] == 'in_progress')
              _buildLocationSharingButton(theme, colorScheme, localizations),
            
            // Bookings List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBookingsList(theme, colorScheme, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHeader(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final status = _currentRide['status'] ?? 'unknown';
    final startTime = _currentRide['startTime'] ?? '';
    final date = _currentRide['date'] ?? '';
    final routeName = _currentRide['route']?['name'] ?? 'Unknown Route';
    
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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (dateTimeDisplay.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateTimeDisplay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartRideButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: _isStartingRide ? null : _startRide,
        icon: _isStartingRide 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isStartingRide ? localizations.startingRide : localizations.startRide),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEndRideButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: _isEndingRide ? null : _endRide,
        icon: _isEndingRide 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.stop),
        label: Text(_isEndingRide ? localizations.endingRide : localizations.endRide),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLocationSharingButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _toggleLocationSharing,
        icon: _isSharingLocation 
            ? const Icon(Icons.location_off, size: 20)
            : const Icon(Icons.location_on, size: 20),
        label: Text(
          _isSharingLocation 
              ? localizations.stopLocationSharing 
              : localizations.startLocationSharing
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: _isSharingLocation ? Colors.red : Colors.blue,
          side: BorderSide(
            color: _isSharingLocation ? Colors.red : Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.noBookingsForRide,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            localizations.passengersCount(_bookings.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bookings.length,
            itemBuilder: (context, index) {
              final booking = _bookings[index];
              return _buildBookingCard(booking, theme, colorScheme, localizations);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final passenger = booking['passenger'] ?? {};
    final fullName = '${passenger['firstName'] ?? ''} ${passenger['lastName'] ?? ''}'.trim();
    final phone = passenger['phone'] ?? '';
    final status = booking['status'] ?? 'unknown';
    final pickupStop = booking['pickupStop'] ?? '';
    final dropoffStop = booking['dropoffStop'] ?? '';

    // Status color and icon
    Color statusColor = colorScheme.onSurface;
    IconData statusIcon = Icons.person;
    String statusText = status;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = localizations.bookingStatusConfirmed;
        break;
      case 'unconfirmed':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = localizations.bookingStatusUnconfirmed;
        break;
      case 'checked_in':
        statusColor = Colors.blue;
        statusIcon = Icons.login;
        statusText = localizations.bookingStatusCheckedIn;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = localizations.bookingStatusCancelled;
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle_outline;
        statusText = localizations.bookingStatusCompleted;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            
            if (pickupStop.isNotEmpty || dropoffStop.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (pickupStop.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${localizations.pickup}: $pickupStop',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (dropoffStop.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${localizations.dropoff}: $dropoffStop',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            
            // Action buttons based on ride status and booking status
            if (_currentRide['status'] == 'in_progress') ...[
              const SizedBox(height: 12),
              if ((status == 'confirmed' || status == 'unconfirmed')) ...[
                // Check-in button for confirmed/unconfirmed passengers
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _updateBookingStatus(booking['_id'], 'checked_in'),
                    icon: const Icon(Icons.login, size: 16),
                    label: Text(localizations.checkIn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ] else if (status == 'checked_in') ...[
                // Dropoff button for checked-in passengers
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _updateBookingStatus(booking['_id'], 'completed'),
                    icon: const Icon(Icons.logout, size: 16),
                    label: Text(localizations.dropOff),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
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