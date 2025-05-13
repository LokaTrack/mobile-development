import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../models/delivery_detail_model.dart';
import '../models/package.dart'; // Add import for Package model

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

  // Method to get check-in packages for return
  Future<List<Package>> getCheckInPackages() async {
    try {
      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Use the dashboard API to get check-in packages
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Check-in packages API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Add proper null checks for data structure
        if (data['data'] == null) {
          debugPrint('Dashboard data is null');
          return [];
        }

        final recentOrders = data['data']['recentOrders'];

        // Check if recentOrders exists and is a list
        if (recentOrders == null) {
          debugPrint('Recent orders is null');
          return [];
        }

        if (recentOrders is! List) {
          debugPrint(
              'Recent orders is not a list: ${recentOrders.runtimeType}');
          return [];
        }

        // Filter for check-in packages and convert to Package objects
        return recentOrders
            .where((order) => order['status'] == 'Check-in')
            .map<Package>((order) {
          // Create a package from dashboard data
          final String id = order['orderNo'] ?? '';
          final String recipient = order['customer'] ?? '';
          final String address = order['address'] ?? '';
          final String items = order['itemsList'] ?? '';

          // Parse the delivery time or use current time if not available
          DateTime scheduledDelivery;
          try {
            scheduledDelivery = order['deliveryStartTime'] != null
                ? DateTime.parse(order['deliveryStartTime'])
                : DateTime.now();
          } catch (e) {
            scheduledDelivery = DateTime.now();
          }

          // Create a package with check-in status
          return Package(
            id: id,
            recipient: recipient,
            address: address,
            items: items,
            status: PackageStatus.checkin,
            scheduledDelivery: scheduledDelivery,
            weight: order['totalWeight']?.toDouble() ?? 0.0,
            totalAmount: order['totalPrice']?.toInt() ?? 0,
            notes: order['orderNotes'] ?? '',
          );
        }).toList();
      } else {
        throw Exception(
            'Failed to load check-in packages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getCheckInPackages: $e');
      // Instead of throwing the exception, return empty list to prevent app crash
      return [];
    }
  }
}
