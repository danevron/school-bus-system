import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'auth_service.dart';
import 'location_foreground_service.dart';

class LocationService extends ChangeNotifier {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal() {
    _foregroundService = LocationForegroundService();
    _initializeService();
  }

  // Private state variables
  bool _isSharingLocation = false;
  String? _currentRideId;
  String? _currentRideName;
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  StreamSubscription<Position>? _locationStreamSubscription;
  late LocationForegroundService _foregroundService;
  
  // Public getters
  bool get isSharingLocation => _isSharingLocation;
  String? get currentRideId => _currentRideId;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Initialize the location service and set up foreground task listeners
  void _initializeService() {
    // Initialize foreground service
    LocationForegroundService.initializeService();
    
    // Listen for data from foreground task
    FlutterForegroundTask.receivePort?.listen((data) {
      if (data == 'stop_location_sharing') {
        // User pressed stop button in notification
        stopLocationSharing();
      }
    });
  }

  /// Start location sharing for a specific ride
  Future<bool> startLocationSharing(String rideId, {String? rideName}) async {
    try {
      // Check if already sharing for this ride
      if (_isSharingLocation && _currentRideId == rideId) {
        return true;
      }

      // Stop any existing location sharing
      await stopLocationSharing();

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Start location sharing
      _currentRideId = rideId;
      _currentRideName = rideName ?? 'Unknown Ride';
      _isSharingLocation = true;

      // Start foreground service
      final foregroundStarted = await _foregroundService.startService(
        rideId: rideId,
        rideName: _currentRideName!,
      );

      if (!foregroundStarted) {
        if (kDebugMode) {
          print('LocationService: Failed to start foreground service');
        }
        // Continue anyway, location sharing will work but won't persist when backgrounded
      }
      
      // Use different strategies for iOS vs Android
      if (Platform.isIOS) {
        await _startIOSLocationSharing();
      } else {
        await _startAndroidLocationSharing();
      }
      
      // Notify listeners of state change
      notifyListeners();
      
      if (kDebugMode) {
        print('LocationService: Started sharing location for ride $rideId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error starting location sharing: $e');
      }
      return false;
    }
  }

  /// Stop location sharing
  Future<void> stopLocationSharing() async {
    if (!_isSharingLocation) return;

    _isSharingLocation = false;
    _currentRideId = null;
    _currentRideName = null;
    // Cancel location updates
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    _lastKnownPosition = null;

    // Stop foreground service
    await _foregroundService.stopService();

    // Notify listeners of state change
    notifyListeners();
    
    if (kDebugMode) {
      print('LocationService: Stopped location sharing');
    }
  }

  /// Send current location to the backend
  Future<void> _sendCurrentLocation() async {
    if (!_isSharingLocation || _currentRideId == null) return;

    try {
      // Get current position with iOS-friendly settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: Platform.isIOS ? LocationAccuracy.best : LocationAccuracy.high,
        timeLimit: Duration(seconds: Platform.isIOS ? 15 : 10), // Longer timeout for iOS
        forceAndroidLocationManager: false, // Use newer location APIs
      );

      // Update last known position
      _lastKnownPosition = position;

      // Prepare location data
      final locationData = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add optional fields if they have valid values
      if (position.speed >= 0) {
        locationData['speed'] = position.speed;
      }
      
      if (position.heading >= 0 && position.heading <= 360) {
        locationData['heading'] = position.heading;
      }
      
      if (position.accuracy > 0) {
        locationData['accuracy'] = position.accuracy;
      }

      if (position.altitude != 0) {
        locationData['altitude'] = position.altitude;
      }

      // Send to backend
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/api/rides/$_currentRideId/location',
        body: locationData,
      );

      if (kDebugMode) {
        print('LocationService: Location sent successfully - Lat: ${position.latitude}, Lng: ${position.longitude}');
      }

      // Notify listeners that we have a new position
      notifyListeners();

    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error sending location: $e');
      }
      
      // Don't stop location sharing for individual failures
      // The timer will try again in the next interval
    }
  }

  /// Get the current position without sending to backend
  Future<Position?> getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _lastKnownPosition = position;
      notifyListeners();
      
      return position;
    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error getting current position: $e');
      }
      return null;
    }
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// iOS-specific location sharing using continuous stream
  Future<void> _startIOSLocationSharing() async {
    try {
      if (kDebugMode) {
        print('LocationService: Starting iOS location sharing');
      }

      // Configure location settings for iOS background location
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      );

      // Use position stream for better iOS background compatibility
      _locationStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _sendLocationUpdate(position);
          notifyListeners();
        },
        onError: (error) {
          if (kDebugMode) {
            print('LocationService iOS: Error in position stream: $error');
          }
          
          // Fall back to timer-based updates if stream fails
          if (_locationTimer == null) {
            _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
              await _sendCurrentLocation();
            });
          }
        },
      );

      // Also get initial location
      await _sendCurrentLocation();

    } catch (e) {
      if (kDebugMode) {
        print('LocationService iOS: Error starting location sharing: $e');
      }
      
      // Fallback to Android approach
      await _startAndroidLocationSharing();
    }
  }

  /// Android-specific location sharing using timer
  Future<void> _startAndroidLocationSharing() async {
    if (kDebugMode) {
      print('LocationService: Starting Android location sharing');
    }

    // Send location updates every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _sendCurrentLocation();
    });
    
    // Send initial location immediately
    await _sendCurrentLocation();
  }

  /// Send location update for a given position
  Future<void> _sendLocationUpdate(Position position) async {
    if (!_isSharingLocation || _currentRideId == null) return;

    try {
      // Prepare location data
      final locationData = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add optional fields if they have valid values
      if (position.speed >= 0) {
        locationData['speed'] = position.speed;
      }
      
      if (position.heading >= 0 && position.heading <= 360) {
        locationData['heading'] = position.heading;
      }
      
      if (position.accuracy > 0) {
        locationData['accuracy'] = position.accuracy;
      }

      if (position.altitude != 0) {
        locationData['altitude'] = position.altitude;
      }

      // Send to backend
      await AuthService.authenticatedRequest(
        'POST',
        '/api/rides/$_currentRideId/location',
        body: locationData,
      );

      if (kDebugMode) {
        print('LocationService: Location sent - Lat: ${position.latitude}, Lng: ${position.longitude}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error sending location update: $e');
      }
    }
  }

  /// Dispose resources when the service is no longer needed
  @override
  void dispose() {
    _locationTimer?.cancel();
    _locationStreamSubscription?.cancel();
    super.dispose();
  }
}