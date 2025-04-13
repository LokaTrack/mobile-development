import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../models/start_delivery_model.dart';

class StartDeliveryService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<StartDeliveryResponse> startDelivery(String orderNo) async {
    try {
      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // URL diubah dari 'delivery/start' menjadi 'delivery' sesuai endpoint yang benar
      final response = await http.post(
        Uri.parse('$baseUrl/delivery'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderNo': orderNo,
        }),
      );

      debugPrint('Start Delivery API status: ${response.statusCode}');
      debugPrint('Start Delivery API response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully started delivery');
          return StartDeliveryResponse.fromJson(responseData);
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to start delivery');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        debugPrint('Bad request: ${response.body}');
        throw Exception(
            responseData['message'] ?? 'Invalid request parameters');
      } else {
        debugPrint(
            'Failed to start delivery. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to start delivery: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error starting delivery: $e');
      throw Exception('Error starting delivery: $e');
    }
  }
}
