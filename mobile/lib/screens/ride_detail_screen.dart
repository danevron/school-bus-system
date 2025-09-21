import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:school_bus_app/widgets/human_readable_date.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'ride_tracking_screen.dart';
import '../utils/formatting_utils.dart';

class RideDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ride;
  final VoidCallback? onRideUpdated;

  const RideDetailScreen({
    super.key,
    required this.ride,
    this.onRideUpdated,
  });

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isStartingRide = false;
  bool _isEndingRide = false;
  List<Map<String, dynamic>> _bookings = [];
  late Map<String, dynamic> _currentRide;
  late LocationService _locationService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
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
    
    // Initialize pulse animation for in-progress rides
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation if ride is in progress
    if (_currentRide['status'] == 'in_progress') {
      _pulseController.repeat(reverse: true);
    }
    
    _loadBookings();
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChange);
    _pulseController.dispose();
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

        bookingsData.forEach((booking) {
          booking['actionable'] = booking['actions']?['canCancel'] == true ||
              booking['actions']?['canConfirm'] == true ||
              booking['actions']?['canCheckIn'] == true ||
              booking['actions']?['canDropOff'] == true;
        });

        // sort by status (non-cancelled first), then by actionable (actionable first)
        bookingsData.sort((a, b) => b['status'].compareTo(a['status']));
        bookingsData.sort((a, b) {
          final aActionable = a['actionable'] == true ? 1 : 0;
          final bActionable = b['actionable'] == true ? 1 : 0;
          return bActionable.compareTo(aActionable);
        });

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
            };
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
        
        // Start pulse animation when ride becomes active
        _pulseController.repeat(reverse: true);
        
        // Notify parent screen that ride was updated
        widget.onRideUpdated?.call();
        
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.rideStartedSuccessfully),
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        
        // Stop pulse animation when ride ends
        _pulseController.stop();
        _pulseController.reset();
        
        // Stop location sharing when ride ends
        await _locationService.stopLocationSharing();
        
        // Notify parent screen that ride was updated
        widget.onRideUpdated?.call();
        
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.rideEndedSuccessfully),
              backgroundColor: Theme.of(context).colorScheme.primary,
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
              backgroundColor: Theme.of(context).colorScheme.primary,
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$cleanedPhone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              _currentRide['route']?['name'] ?? localizations.rideDetails,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            _buildAppBarStatusBadge(theme, colorScheme, localizations),
          ],
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

  Widget _buildAppBarStatusBadge(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final status = _currentRide['status'] ?? 'unknown';
    
    // Status color and translated text
    Color statusColor = colorScheme.onSurfaceVariant;
    String statusText = status;
    bool isInProgress = false;
    
    switch (status.toLowerCase()) {
      case 'in_progress':
        statusColor = colorScheme.primary;
        statusText = localizations.rideStatusActive;
        isInProgress = true;
        break;
      case 'completed':
        statusColor = colorScheme.onSurfaceVariant;
        statusText = localizations.rideStatusCompleted;
        break;
      case 'cancelled':
        statusColor = colorScheme.error;
        statusText = localizations.rideStatusCancelled;
        break;
      case 'scheduled':
        statusColor = colorScheme.primary;
        statusText = localizations.rideStatusScheduled;
        break;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: isInProgress ? Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInProgress) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (isInProgress) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: badge,
          );
        },
      );
    }

    return badge;
  }

  Widget _buildRideHeader(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final startTime = _currentRide['startTime'] ?? '';
    final date = _currentRide['date'] ?? '';

    final formattedStartTime = FormattingUtils.formatTime(startTime);

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
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              HumanReadableDate(
                dateString: date,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                showYear: false,
              ),
              const SizedBox(width: 8),
              Text(
                formattedStartTime,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
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
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    localizations.startRide,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          backgroundColor: colorScheme.error,
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
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop, size: 20),
                  SizedBox(width: 8),
                  Text(
                    localizations.endRide,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          foregroundColor: _isCurrentRideSharing ? colorScheme.error : colorScheme.primary,
          side: BorderSide(
            color: _isCurrentRideSharing ? colorScheme.error : colorScheme.primary,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCurrentRideSharing ? Icons.location_off : Icons.my_location,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              _isCurrentRideSharing
                  ? localizations.stopLocationSharing 
                  : localizations.startLocationSharing,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _isCurrentRideSharing ? colorScheme.error : colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, size: 20),
            SizedBox(width: 8),
            Text(
              localizations.trackRide,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
            localizations.passengersCount(_bookings.where((b) => b['status'] != 'cancelled').length),
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
    final isGuest = passenger['isGuest'] ?? false;
    final status = booking['status'] ?? 'unknown';
    final pickupStop = booking['pickupStop'] ?? '';
    final dropoffStop = booking['dropoffStop'] ?? '';

    // Status color and translated text
    Color statusColor = colorScheme.onSurfaceVariant;
    String statusText = status;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = colorScheme.primary;
        statusText = localizations.bookingStatusConfirmed;
        break;
      case 'unconfirmed':
        statusColor = colorScheme.secondary;
        statusText = localizations.bookingStatusUnconfirmed;
        break;
      case 'checked_in':
        statusColor = colorScheme.tertiary;
        statusText = localizations.bookingStatusCheckedIn;
        break;
      case 'cancelled':
        statusColor = colorScheme.error;
        statusText = localizations.bookingStatusCancelled;
        break;
      case 'completed':
        statusColor = colorScheme.onSurfaceVariant;
        statusText = localizations.bookingStatusCompleted;
        break;
      case 'waiting_list':
        statusColor = colorScheme.secondary;
        statusText = localizations.bookingStatusWaitingList;
        break;
    }

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (isGuest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              localizations.guest,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _makePhoneCall(phone),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phone,
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
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined, size: 16),
                SizedBox(width: 6),
                Text(
                  localizations.cancel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 16),
                SizedBox(width: 6),
                Text(
                  localizations.confirm,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              foregroundColor: colorScheme.tertiary,
              side: BorderSide(color: colorScheme.tertiary, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login, size: 16),
                SizedBox(width: 6),
                Text(
                  localizations.checkIn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, size: 16),
                SizedBox(width: 6),
                Text(
                  localizations.dropOff,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CancellationConfirmationModal(
        bookingId: bookingId,
      ),
    );

    if (confirmed == true) {
      await _updateBookingStatus(bookingId, 'cancel');
    }
  }
}

class _CancellationConfirmationModal extends StatelessWidget {
  final String bookingId;

  const _CancellationConfirmationModal({
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
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
                Text(
                  localizations.confirmCancellation,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.confirmCancellationMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 60, left: 20, right: 20),
            child: ElevatedButton.icon(
              label: Text(localizations.cancel),
              icon: const Icon(Icons.delete_forever, size: 16),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}