import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize Firebase and notification services
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase with platform-specific configuration
      if (Firebase.apps.isEmpty) {
        print('Initializing Firebase...');
        await Firebase.initializeApp();
        print('Firebase initialized successfully');
      } else {
        print('Firebase already initialized');
      }
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Handle initial notification when app is opened from terminated state
      _handleInitialMessage();
      
      // Automatically register FCM token if user is authenticated
      if (AuthService.isAuthenticated) {
        _registerTokenSilently();
      }
      
      _initialized = true;
      print('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing NotificationService: $e');
      print('Stack trace: $stackTrace');
      // Don't set _initialized to true if there's an error
      return;
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    // Request FCM permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined notification permission');
    }
  }

  /// Set up FCM message handlers
  static void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle initial notification when app is opened from terminated state
  static Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.messageId}');
        // Delay navigation until the app is fully loaded
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle notification tap (when app is opened from notification)
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    await _processNotificationAction(message);
  }

  /// Handle local notification tap
  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        await _navigateToRideDetail(data);
      } catch (e) {
        print('Error processing notification tap: $e');
      }
    }
  }

  /// Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_confirmations',
      'Ride Confirmations',
      channelDescription: 'Notifications for ride confirmations and cancellations',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('confirm', 'Confirm Ride'),
        AndroidNotificationAction('cancel', 'Cancel Booking'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  /// Process notification actions (confirm/cancel)
  static Future<void> _processNotificationAction(RemoteMessage message) async {
    final data = message.data;
    final rideId = data['rideId'];
    final bookingId = data['bookingId'];
    
    if (rideId != null) {
      await _navigateToRideDetail({'rideId': rideId, 'bookingId': bookingId});
    }
  }

  /// Navigate to ride detail page
  static Future<void> _navigateToRideDetail(Map<String, dynamic> data) async {
    try {
      final rideId = data['rideId'];
      final bookingId = data['bookingId'];
      
      if (rideId == null || navigatorKey?.currentState == null) {
        print('Cannot navigate: missing rideId or navigator not available');
        return;
      }

      // Fetch full ride data from API
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/api/rides/$rideId',
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final ride = responseData['data']?['ride'];
        
        if (ride != null) {
          // Navigate to ride detail screen
          navigatorKey!.currentState!.pushNamed(
            '/ride-detail',
            arguments: {'ride': ride, 'bookingId': bookingId},
          );
        } else {
          print('Ride data not found in response');
        }
      } else {
        print('Failed to fetch ride data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error navigating to ride detail: $e');
    }
  }

  /// Silently register FCM token with backend (for production)
  static Future<void> _registerTokenSilently() async {
    try {
      // On iOS, get APNS token first (required for FCM)
      if (Platform.isIOS) {
        await _firebaseMessaging.getAPNSToken();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        await _registerTokenWithBackend(token);
        
        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_registerTokenWithBackend);
        
        print('FCM token registered successfully');
      }
    } catch (e) {
      // Silent failure in production - log but don't show user errors
      print('FCM token registration failed: $e');
    }
  }

  /// Get FCM token and register with backend (for manual testing)
  static Future<String?> getTokenAndRegister() async {
    try {
      String? token;
      
      // On iOS, get APNS token first (required for FCM)
      if (Platform.isIOS) {
        await _firebaseMessaging.getAPNSToken();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        await _registerTokenWithBackend(token);
        
        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_registerTokenWithBackend);
      }
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Register FCM token with backend
  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/api/notifications/register-token',
        body: {'fcmToken': token},
      );
      
      if (response.statusCode == 200) {
        print('FCM token registered successfully');
      } else {
        print('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  /// Handle notification actions (confirm/cancel booking)
  static Future<void> handleBookingAction(String action, String bookingId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/api/notifications/booking-action',
        body: {
          'action': action, // 'confirm' or 'cancel'
          'bookingId': bookingId,
        },
      );
      
      if (response.statusCode == 200) {
        print('Booking action processed successfully: $action');
      } else {
        print('Failed to process booking action: ${response.statusCode}');
      }
    } catch (e) {
      print('Error processing booking action: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
  
  // Process the background message
  // Note: Cannot show UI or navigate in background handler
}