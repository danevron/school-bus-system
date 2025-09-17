import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'ride_tracking_screen.dart';

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
  List<Map<String, dynamic>> _bookings = [];
  late Map<String, dynamic> _currentRide;
  late LocationService _locationService;
  
  bool get _isDriver => AuthService.user?['role'] == 'driver';
  
  bool get _isCurrentRideSharing => 
      _locationService.isSharingLocation && 
      _locationService.currentRideId == _currentRide['_id'];

  @override
  void initState() {
    super.initState();
    _currentRide = Map<String, dynamic>.from(widget.ride);
    _locationService = LocationService();
    _locationService.addListener(_onLocationServiceChange);
    _loadBookings();
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChange);
    super.dispose();
  }

  void _onLocationServiceChange() {
    if (mounted) {
      setState(() {
        // Trigger UI rebuild when location service state changes
      });
    }
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
              'actions': booking['actions'] ?? {
                'canCancel': false,
                'canConfirm': false,
                'canCheckIn': false,
                'canDropOff': false,
              },
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
        await _locationService.stopLocationSharing();
        
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
    final rideId = _currentRide['_id'] as String;
    final rideName = _currentRide['route']?['name'] as String? ?? 'Unknown Ride';
    
    if (_locationService.isSharingLocation && _locationService.currentRideId == rideId) {
      await _locationService.stopLocationSharing();
    } else {
      final success = await _locationService.startLocationSharing(rideId, rideName: rideName);
      
      if (!success && mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.locationPermissionRequired),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }


  Future<void> _updateBookingStatus(String bookingId, String action) async {
    try {
      String endpoint;
      String successMessage;
      Map<String, dynamic>? body;
      
      // Handle different booking actions
      switch (action) {
        case 'checkin':
          endpoint = '/api/bookings/$bookingId/checkin';
          successMessage = AppLocalizations.of(context)!.passengerCheckedInSuccessfully;
          break;
        case 'dropoff':
          endpoint = '/api/bookings/$bookingId/dropoff';
          successMessage = AppLocalizations.of(context)!.passengerDroppedOffSuccessfully;
          break;
        case 'confirm':
          endpoint = '/api/bookings/$bookingId/confirm';
          successMessage = AppLocalizations.of(context)!.bookingConfirmedSuccessfully;
          break;
        case 'cancel':
          endpoint = '/api/bookings/$bookingId/cancel';
          successMessage = AppLocalizations.of(context)!.bookingCancelledSuccessfully;
          body = {'reason': 'Cancelled by user'};
          break;
        default:
          throw Exception('Unsupported action: $action');
      }

      final response = await AuthService.authenticatedRequest(
        'POST',
        endpoint,
        body: body,
      );
      
      if (response.statusCode == 200) {
        // Refresh bookings list to get updated data and actions
        await _loadBookings();
        
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _currentRide['route']?['name'] ?? localizations.rideDetails,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ride Status Header
            _buildRideHeader(theme, colorScheme, localizations),
            
            // Driver-only controls
            if (_isDriver) ...[
              // Start Ride Button (only for scheduled rides)
              if (_currentRide['status'] == 'scheduled')
                _buildStartRideButton(theme, colorScheme, localizations),
              
              // End Ride Button (only for in-progress rides)
              if (_currentRide['status'] == 'in_progress')
                _buildEndRideButton(theme, colorScheme, localizations),
              
              // Location Sharing Button (only for in-progress rides)
              if (_currentRide['status'] == 'in_progress')
                _buildLocationSharingButton(theme, colorScheme, localizations),
            ],
            
            // Track Ride Button (for in-progress rides - all users)
            if (_currentRide['status'] == 'in_progress')
              _buildTrackRideButton(theme, colorScheme, localizations),
            
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (dateTimeDisplay.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        dateTimeDisplay,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartRideButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
      child: ElevatedButton(
        onPressed: _isStartingRide ? null : _startRide,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
        child: _isStartingRide
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                localizations.startRide,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildEndRideButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
      child: ElevatedButton(
        onPressed: _isEndingRide ? null : _endRide,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
        child: _isEndingRide
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                localizations.endRide,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildLocationSharingButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
      child: OutlinedButton(
        onPressed: _toggleLocationSharing,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: _isCurrentRideSharing ? const Color(0xFFD32F2F) : const Color(0xFF10B981),
          side: BorderSide(
            color: _isCurrentRideSharing ? const Color(0xFFD32F2F) : const Color(0xFF10B981),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(
          _isCurrentRideSharing
              ? localizations.stopLocationSharing 
              : localizations.startLocationSharing,
          style: theme.textTheme.titleMedium?.copyWith(
            color: _isCurrentRideSharing ? const Color(0xFFD32F2F) : const Color(0xFF10B981),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackRideButton(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RideTrackingScreen(
                rideId: _currentRide['_id'],
                rideName: _currentRide['route']?['name'] ?? 'Ride',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(
          localizations.trackRide,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
          child: Text(
            localizations.passengersCount(_bookings.length),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
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

    // Status color and translated text
    Color statusColor = const Color(0xFF6B7280);
    String statusText = status;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = const Color(0xFF10B981);
        statusText = localizations.bookingStatusConfirmed;
        break;
      case 'unconfirmed':
        statusColor = const Color(0xFFF59E0B);
        statusText = localizations.bookingStatusUnconfirmed;
        break;
      case 'checked_in':
        statusColor = const Color(0xFF3B82F6);
        statusText = localizations.bookingStatusCheckedIn;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFD32F2F);
        statusText = localizations.bookingStatusCancelled;
        break;
      case 'completed':
        statusColor = const Color(0xFF6B7280);
        statusText = localizations.bookingStatusCompleted;
        break;
      case 'waiting_list':
        statusColor = const Color(0xFFF59E0B);
        statusText = localizations.bookingStatusWaitingList;
        break;
    }

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
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
            ],
          ),
          
          if (pickupStop.isNotEmpty || dropoffStop.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (pickupStop.isNotEmpty) ...[
              Text(
                '${localizations.pickup}: $pickupStop',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
            if (dropoffStop.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${localizations.dropoff}: $dropoffStop',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ],
          
          // Dynamic action buttons based on API permissions
          _buildActionButtons(booking, theme, colorScheme, localizations),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking, ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final actions = booking['actions'] as Map<String, dynamic>? ?? {};
    final List<Widget> actionButtons = [];

    // Check if any actions are available
    final hasActions = actions['canCancel'] == true ||
        actions['canConfirm'] == true ||
        actions['canCheckIn'] == true ||
        actions['canDropOff'] == true;

    if (!hasActions) {
      return const SizedBox.shrink();
    }

    actionButtons.add(const SizedBox(height: 12));

    // Cancel button
    if (actions['canCancel'] == true) {
      actionButtons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showCancelConfirmation(booking['_id']),
            style: OutlinedButton.styleFrom(
              elevation: 0,
              foregroundColor: const Color(0xFFD32F2F),
              side: const BorderSide(color: Color(0xFFD32F2F), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              localizations.cancel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
      actionButtons.add(const SizedBox(height: 8));
    }

    // Confirm button
    if (actions['canConfirm'] == true) {
      actionButtons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _updateBookingStatus(booking['_id'], 'confirm'),
            style: OutlinedButton.styleFrom(
              elevation: 0,
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              localizations.confirm,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
      actionButtons.add(const SizedBox(height: 8));
    }

    // Check-in button
    if (actions['canCheckIn'] == true) {
      actionButtons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _updateBookingStatus(booking['_id'], 'checkin'),
            style: OutlinedButton.styleFrom(
              elevation: 0,
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              localizations.checkIn,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
      actionButtons.add(const SizedBox(height: 8));
    }

    // Drop-off button
    if (actions['canDropOff'] == true) {
      actionButtons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _updateBookingStatus(booking['_id'], 'dropoff'),
            style: OutlinedButton.styleFrom(
              elevation: 0,
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              localizations.dropOff,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: actionButtons,
    );
  }

  Future<void> _showCancelConfirmation(String bookingId) async {
    final localizations = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.confirmCancellation),
          content: Text(localizations.confirmCancellationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(localizations.confirmCancellation),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _updateBookingStatus(bookingId, 'cancel');
    }
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