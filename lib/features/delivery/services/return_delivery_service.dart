import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_service.dart';

class ReturnDeliveryService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> submitReturnDelivery({
    required String orderNo,
    required String reason,
    required List<Map<String, dynamic>> returnItems,
    required List<File> images,
    String? notes,
  }) async {
    try {
      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/delivery/return'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept-Encoding': 'gzip, deflate, br',
      });

      // Add text fields
      request.fields['orderNo'] = orderNo;
      request.fields['reason'] = reason;

      // Convert returnItems list to JSON string
      final List<Map<String, dynamic>> formattedItems = returnItems.map((item) {
        return {"name": item['name'], "quantity": item['qty']};
      }).toList();

      request.fields['returnItem'] = jsonEncode(formattedItems);

      // Add notes if provided
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = file.path.split('/').last;
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        final multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: fileName,
        );

        request.files.add(multipartFile);
        debugPrint('Added image file: $fileName');
      }

      debugPrint('Submitting return request for order: $orderNo');
      debugPrint('Return items: ${jsonEncode(formattedItems)}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Return API response status: ${response.statusCode}');

      // Parse the response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == 'success') {
          debugPrint('Successfully submitted return request');
          return responseData;
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to submit return request');
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
            'Failed to submit return. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            responseData['message'] ?? 'Failed to submit return request');
      }
    } catch (e) {
      debugPrint('Error submitting return: $e');
      throw Exception('Error submitting return: $e');
    }
  }
}
