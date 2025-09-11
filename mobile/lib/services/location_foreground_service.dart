import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/foundation.dart';

/// The [LocationForegroundService] manages the foreground service
/// that keeps location sharing active even when the app is backgrounded.
class LocationForegroundService {
  static final LocationForegroundService _instance = LocationForegroundService._internal();
  factory LocationForegroundService() => _instance;
  LocationForegroundService._internal();

  bool _isServiceRunning = false;
  
  bool get isServiceRunning => _isServiceRunning;

  /// Initialize the foreground service
  static void initializeService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_service',
        channelName: 'School Bus Location Service',
        channelDescription: 'Keeps location sharing active for school bus tracking',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // 5 seconds interval
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start the foreground service
  Future<bool> startService({
    required String rideId,
    required String rideName,
  }) async {
    try {
      // Check if service is already running
      if (_isServiceRunning) {
        if (kDebugMode) {
          print('LocationForegroundService: Service already running');
        }
        return true;
      }

      // Request notification permission
      final NotificationPermission notificationPermission = 
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // Start the foreground service
      await FlutterForegroundTask.startService(
        notificationTitle: 'School Bus Location Sharing',
        notificationText: 'Sharing location for ride: $rideName',
        callback: startLocationCallback,
      );

      _isServiceRunning = true;
      if (kDebugMode) {
        print('LocationForegroundService: Service started successfully for ride $rideId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('LocationForegroundService: Error starting service: $e');
      }
      return false;
    }
  }

  /// Stop the foreground service
  Future<bool> stopService() async {
    try {
      if (!_isServiceRunning) {
        if (kDebugMode) {
          print('LocationForegroundService: Service not running');
        }
        return true;
      }

      await FlutterForegroundTask.stopService();
      
      _isServiceRunning = false;
      if (kDebugMode) {
        print('LocationForegroundService: Service stopped successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('LocationForegroundService: Error stopping service: $e');
      }
      return false;
    }
  }

  /// Update the notification text
  Future<void> updateNotification({
    required String rideName,
    String? additionalInfo,
  }) async {
    if (!_isServiceRunning) return;

    try {
      String notificationText = 'Sharing location for ride: $rideName';
      if (additionalInfo != null) {
        notificationText += '\n$additionalInfo';
      }

      await FlutterForegroundTask.updateService(
        notificationTitle: 'School Bus Location Sharing',
        notificationText: notificationText,
      );
    } catch (e) {
      if (kDebugMode) {
        print('LocationForegroundService: Error updating notification: $e');
      }
    }
  }

  /// Check if the service is running
  Future<bool> checkServiceStatus() async {
    final bool isRunning = await FlutterForegroundTask.isRunningService;
    _isServiceRunning = isRunning;
    return isRunning;
  }
}

/// The callback function for the foreground task
@pragma('vm:entry-point')
void startLocationCallback() {
  // Initialize the task handler
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

/// The task handler that runs in the foreground service
class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (kDebugMode) {
      print('LocationTaskHandler: Foreground task started');
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // This method is called periodically based on the interval
    // We can use this to check if location service is still active
    // and update the notification or perform other background tasks
    
    if (kDebugMode) {
      print('LocationTaskHandler: Foreground task repeat event at $timestamp');
    }

    // Send periodic updates to main isolate if needed
    FlutterForegroundTask.sendDataToMain('location_service_active');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    if (kDebugMode) {
      print('LocationTaskHandler: Foreground task destroyed');
    }
  }

  @override
  void onButtonPressed(String id) {
    if (kDebugMode) {
      print('LocationTaskHandler: Button pressed: $id');
    }
    
    // Handle notification button presses
    if (id == 'stop_service') {
      // Stop location sharing when user presses the stop button
      FlutterForegroundTask.sendDataToMain('stop_location_sharing');
    }
  }

  @override
  void onNotificationPressed() {
    if (kDebugMode) {
      print('LocationTaskHandler: Notification pressed');
    }
    
    // Open the app when notification is pressed
    FlutterForegroundTask.launchApp('/ride_detail');
  }
}