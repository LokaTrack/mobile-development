import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../models/delivery_detail_model.dart';

class DeliveryDetailService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<DeliveryDetailData> getDeliveryDetail(String orderNo) async {
    try {
      // Double encode the orderNo as required by the API
      final String encodedOrderNo =
          Uri.encodeComponent(Uri.encodeComponent(orderNo));

      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/delivery/$encodedOrderNo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delivery detail API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully fetched delivery detail data');
          return DeliveryDetailData.fromJson(responseData['data']);
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to fetch delivery detail');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
            'Failed to fetch delivery detail. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to fetch delivery detail: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching delivery detail: $e');
      throw Exception('Error fetching delivery detail: $e');
    }
  }
}
