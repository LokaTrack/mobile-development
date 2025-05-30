import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../models/delivery_model.dart';

class DeliveryService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<DeliveryListModel> getAllDeliveries() async {
    try {
      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/deliveries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Deliveries API status: ${response.statusCode}');
      debugPrint('Deliveries API response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully fetched deliveries data');
          return DeliveryListModel.fromJson(responseData);
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to fetch deliveries');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
            'Failed to fetch deliveries. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch deliveries: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
      throw Exception('Error fetching deliveries: $e');
    }
  }
}
