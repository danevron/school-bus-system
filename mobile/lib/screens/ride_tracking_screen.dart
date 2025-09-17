import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../utils/map_config.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final String rideName;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
    required this.rideName,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _locationTimer;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _rideProgress;
  List<Map<String, dynamic>> _busStops = [];
  
  // Default center (can be updated based on first location)
  LatLng _mapCenter = const LatLng(32.0853, 34.7818); // Tel Aviv as default
  double _mapZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRideDetails() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/rides/${widget.rideId}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final rideData = responseData['data']?['ride'] as Map<String, dynamic>?;
        
        if (rideData != null) {
          final route = rideData['route'] as Map<String, dynamic>?;
          if (route != null) {
            final stops = route['stops'] as List? ?? [];
            
            setState(() {
              _busStops = stops.map<Map<String, dynamic>>((stop) {
                final stopMap = stop as Map<String, dynamic>;
                return {
                  '_id': stopMap['_id'] ?? '',
                  'name': stopMap['name'] ?? 'Unknown Stop',
                  'address': stopMap['address'] ?? '',
                  'coordinates': {
                    'latitude': stopMap['coordinates']?['latitude']?.toDouble() ?? 0.0,
                    'longitude': stopMap['coordinates']?['longitude']?.toDouble() ?? 0.0,
                  },
                  'estimatedArrivalTime': stopMap['estimatedArrivalTime'] ?? '',
                };
              }).where((stop) {
                // Only include stops with valid coordinates
                final coords = stop['coordinates'] as Map<String, dynamic>;
                return coords['latitude'] != 0.0 && coords['longitude'] != 0.0;
              }).toList();
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching ride details: $e');
      // Don't show error to user for stops, it's not critical
    }
  }

  void _startLocationTracking() {
    // Get initial location
    _fetchRideLocation();
    
    // Start polling every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRideLocation();
    });
  }

  Future<void> _fetchRideLocation() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/rides/${widget.rideId}/progress',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          final currentLocationData = data['currentLocation'] as Map<String, dynamic>?;
          
          if (currentLocationData != null) {
            final coordinates = currentLocationData['coordinates'] as Map<String, dynamic>?;
            
            if (coordinates != null) {
              final lat = coordinates['latitude']?.toDouble();
              final lng = coordinates['longitude']?.toDouble();
              
              if (lat != null && lng != null) {
                final newLocation = LatLng(lat, lng);
                
                setState(() {
                  _currentLocation = newLocation;
                  _rideProgress = data;
                  _isLoading = false;
                  _error = null;
                  
                  // Update map center on first location or if map is not yet centered
                  if (_mapCenter == const LatLng(32.0853, 34.7818)) {
                    _mapCenter = newLocation;
                    // Only move the map if it's already been rendered
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        try {
                          _mapController.move(newLocation, _mapZoom);
                        } catch (e) {
                          // Map controller not ready yet, will be centered when map builds
                        }
                      }
                    });
                  }
                });
              }
            }
          } else {
            final localizations = AppLocalizations.of(context)!;
            setState(() {
              _error = localizations.noLocationData;
              _isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        final localizations = AppLocalizations.of(context)!;
        setState(() {
          _error = localizations.rideNotStarted;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to get ride location: ${response.statusCode}');
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context)!;
      setState(() {
        _error = '${localizations.errorLoadingLocation}: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _centerOnBus() {
    if (_currentLocation != null) {
      try {
        _mapController.move(_currentLocation!, _mapZoom);
      } catch (e) {
        // Map controller not ready yet, ignore
      }
    }
  }

  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final newZoom = (currentZoom + 1).clamp(8.0, 19.0);
      _mapController.move(_mapController.camera.center, newZoom);
      setState(() {
        _mapZoom = newZoom;
      });
    } catch (e) {
      // Map controller not ready yet, ignore
    }
  }

  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final newZoom = (currentZoom - 1).clamp(8.0, 19.0);
      _mapController.move(_mapController.camera.center, newZoom);
      setState(() {
        _mapZoom = newZoom;
      });
    } catch (e) {
      // Map controller not ready yet, ignore
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
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.trackingRide(widget.rideName),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          if (_currentLocation != null)
            IconButton(
              icon: Icon(
                Icons.my_location,
                color: colorScheme.primary,
              ),
              onPressed: _centerOnBus,
              tooltip: localizations.centerOnBus,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme, colorScheme, localizations)
              : _buildMapView(theme, colorScheme, localizations),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.locationUnavailable,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchRideLocation();
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                localizations.retry,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    return Column(
      children: [
        // Ride status info
        if (_rideProgress != null) _buildRideStatusCard(theme, colorScheme, localizations),
        
        // Map with zoom controls
        Expanded(
          child: Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: _mapZoom,
                  minZoom: 8.0,
                  maxZoom: 19.0,
                ),
                children: [
                  // Tile layer (Platform-specific)
                  TileLayer(
                    urlTemplate: MapTileConfig.getTileUrlTemplate(),
                    subdomains: MapTileConfig.getSubdomains(),
                    userAgentPackageName: 'com.example.school_bus_app',
                    additionalOptions: MapTileConfig.getAdditionalOptions(),
                  ),
                  
                  // Markers layer (bus stops and bus)
                  MarkerLayer(
                    markers: _buildAllMarkers(colorScheme),
                  ),
                ],
              ),
              
              // Zoom controls
              Positioned(
                right: 16,
                top: 16,
                child: _buildZoomControls(colorScheme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Marker> _buildAllMarkers(ColorScheme colorScheme) {
    final markers = <Marker>[];

    // Add bus stop markers
    for (final stop in _busStops) {
      final coords = stop['coordinates'] as Map<String, dynamic>;
      final lat = coords['latitude'] as double;
      final lng = coords['longitude'] as double;
      
      if (lat != 0.0 && lng != 0.0) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            child: _buildBusStopMarker(stop, colorScheme),
          ),
        );
      }
    }

    // Add bus marker (on top of stops)
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          child: _buildBusMarker(colorScheme),
        ),
      );
    }

    return markers;
  }

  Widget _buildBusStopMarker(Map<String, dynamic> stop, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showStopInfo(stop),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_bus_filled,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildBusMarker(ColorScheme colorScheme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_bus,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  void _showStopInfo(Map<String, dynamic> stop) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            stop['name'] ?? 'Bus Stop',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          content: stop['address']?.isNotEmpty == true 
            ? Text(
                stop['address'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                localizations.cancel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoomControls(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom In button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _zoomIn,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              child: Icon(
                Icons.add,
                color: colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
        
        // Divider line
        Container(
          width: 44,
          height: 1,
          color: colorScheme.outline.withOpacity(0.2),
        ),
        
        // Zoom Out button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _zoomOut,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: Icon(
                Icons.remove,
                color: colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideStatusCard(ThemeData theme, ColorScheme colorScheme, AppLocalizations localizations) {
    final lastUpdate = _rideProgress?['lastUpdated'] as String?;
    final status = _rideProgress?['status'] as String?;
    final isActive = _rideProgress?['isActive'] as bool? ?? false;
    final totalDistance = _rideProgress?['totalDistance'] as num? ?? 0;
    
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
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                localizations.rideInProgress,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (lastUpdate != null)
                Text(
                  _formatLastUpdate(lastUpdate, localizations),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (totalDistance > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Total Distance: ${(totalDistance / 1000).toStringAsFixed(1)} km',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastUpdate(String timestamp, AppLocalizations localizations) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inSeconds < 60) {
        return localizations.justNow;
      } else if (difference.inMinutes < 60) {
        return localizations.minutesAgo(difference.inMinutes);
      } else {
        return localizations.hoursAgo(difference.inHours);
      }
    } catch (e) {
      return localizations.unknownTime;
    }
  }
}