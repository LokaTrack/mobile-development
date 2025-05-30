import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../models/return_detail_model.dart';

class ReturnDetailService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<ReturnDetailModel> getReturnDetail(String orderNo) async {
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
        Uri.parse('$baseUrl/delivery/return/$encodedOrderNo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Return detail API status: ${response.statusCode}');
      debugPrint('Return detail API response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully fetched return detail data');
          return ReturnDetailModel.fromJson(responseData);
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to fetch return detail');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
            'Failed to fetch return detail. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to fetch return detail: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching return detail: $e');
      throw Exception('Error fetching return detail: $e');
    }
  }
}
