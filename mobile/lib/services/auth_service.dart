import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:3000'; // TODO: Make this configurable
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  static String? _token;
  static Map<String, dynamic>? _user;
  
  // Getters
  static bool get isAuthenticated => _token != null;
  static String? get token => _token;
  static Map<String, dynamic>? get user => _user;
  
  // Initialize auth service by loading stored data
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      _user = json.decode(userData);
    }
  }
  
  // Login with email and password
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store token and user data
        _token = data['token'];
        _user = data['user'];
        
        // Persist to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userKey, json.encode(_user));
        
        // Register FCM token after successful login
        try {
          await NotificationService.getTokenAndRegister();
        } catch (e) {
          print('Failed to register FCM token: $e');
          // Don't fail login if FCM registration fails
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': _user,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Logout
  static Future<void> logout() async {
    _token = null;
    _user = null;
    
    // Clear from storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
  
  // Get headers with authorization
  static Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }
  
  // Helper method to make authenticated API calls
  static Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    final headers = getAuthHeaders();
    
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}