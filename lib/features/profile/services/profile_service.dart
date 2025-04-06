import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/services/auth_service.dart';

class ProfileService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Get token using AuthService instead of directly from SharedPreferences
      final token = await _authService.getToken();

      debugPrint(
          'Token retrieval attempt: ${token != null ? 'Success' : 'Failed'}');

      if (token == null || token.isEmpty) {
        // Check SharedPreferences directly as a fallback
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('user_data');
        debugPrint('Fallback - user_data exists: ${userData != null}');

        if (userData != null) {
          final userMap = json.decode(userData);
          final fallbackToken = userMap['token'];

          if (fallbackToken != null) {
            debugPrint('Retrieved token from user_data fallback');
            return _fetchProfileWithToken(fallbackToken);
          }
        }

        throw Exception('No access token found. Please login again.');
      }

      return _fetchProfileWithToken(token);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      throw Exception('Error getting profile: $e');
    }
  }

  // Separate method to fetch profile with a token
  Future<Map<String, dynamic>> _fetchProfileWithToken(String token) async {
    debugPrint('Fetching profile with token: ${_maskToken(token)}');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Profile API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint(
            'Response body: ${response.body.substring(0, min(100, response.body.length))}...');

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully fetched profile data');
          return _sanitizeProfileData(responseData['data']);
        } else {
          debugPrint(
              'API returned success but with invalid data format: ${response.body}');
          throw Exception('Invalid data format received from server');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
            'Failed to load profile. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Helper to sanitize and validate profile data
  Map<String, dynamic> _sanitizeProfileData(Map<String, dynamic> data) {
    // Create a new map with validated data
    final Map<String, dynamic> sanitized = {};

    // Safety convert all values to their expected types
    sanitized['username'] = data['username']?.toString() ?? '-';
    sanitized['email'] = data['email']?.toString() ?? '-';
    sanitized['phoneNumber'] = data['phoneNumber']?.toString() ?? '-';
    sanitized['profilePictureUrl'] =
        data['profilePictureUrl']?.toString() ?? '';

    // Convert delivery stats
    sanitized['deliveredPackages'] = _safelyParseInt(data['deliveredPackages']);
    sanitized['totalDeliveries'] = _safelyParseInt(data['totalDeliveries']);

    // Safely parse percentage
    if (data['percentage'] != null) {
      try {
        sanitized['percentage'] = double.parse(data['percentage'].toString());
      } catch (e) {
        sanitized['percentage'] = 0.0;
      }
    } else {
      sanitized['percentage'] = 0.0;
    }

    // Dates
    sanitized['registrationDate'] = data['registrationDate']?.toString() ?? '';
    sanitized['lastUpdate'] = data['lastUpdate']?.toString() ?? '';

    // Extra fields
    sanitized['role'] = data['role']?.toString() ?? 'driver';
    sanitized['userId'] = data['userId']?.toString() ?? '';
    sanitized['emailVerified'] = data['emailVerified'] == true;

    return sanitized;
  }

  // Safely parse integer values
  int _safelyParseInt(dynamic value) {
    if (value == null) return 0;

    try {
      if (value is int) return value;
      return int.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }

  // Mask token for logging
  String _maskToken(String token) {
    if (token.length <= 10) return '***';
    return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
  }

  // Helper function to get min value
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
