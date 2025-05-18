import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';

class PackageUpdateService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> updatePackageStatus({
    required String orderNo,
    required String deliveryStatus,
  }) async {
    try {
      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Create the request body
      final Map<String, dynamic> requestBody = {
        'orderNo': orderNo,
        'deliveryStatus': deliveryStatus,
      };

      debugPrint('Updating package status: $requestBody'); // Make API request
      final response = await http.put(
        Uri.parse('$baseUrl/delivery'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Update status API response status: ${response.statusCode}');

      // Parse the response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == 'success') {
          debugPrint('Successfully updated package status');
          return responseData;
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to update package status');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        // Bad request
        debugPrint('Bad request: ${response.body}');
        throw Exception(
            responseData['message'] ?? 'Invalid request parameters');
      } else {
        debugPrint(
            'Failed to update package. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            responseData['message'] ?? 'Failed to update package status');
      }
    } catch (e) {
      debugPrint('Error updating package status: $e');
      throw Exception('Error updating package status: $e');
    }
  }
}
