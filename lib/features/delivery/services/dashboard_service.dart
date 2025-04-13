import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';
import '../../auth/services/auth_service.dart';

class DashboardService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<DashboardModel> getDashboardData() async {
    try {
      // Get auth token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Make API request with authorization header
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug response
      debugPrint('Dashboard API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully fetched dashboard data');
          return DashboardModel.fromJson(responseData['data']);
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
            'Failed to load dashboard. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }
}
