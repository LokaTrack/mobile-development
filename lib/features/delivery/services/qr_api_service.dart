import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';

class QrApiService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  /// Get order number from QR URL using POST request with JSON body
  Future<QrOrderResponse> getOrderNumberFromUrl(String qrUrl) async {
    try {
      debugPrint('🔍 Extracting order number from QR URL: $qrUrl');

      // Validate QR URL format
      if (qrUrl.isEmpty) {
        throw Exception('QR URL is empty');
      }

      // Check if the QR URL looks like a valid URL
      if (!qrUrl.startsWith('http://') && !qrUrl.startsWith('https://')) {
        debugPrint('⚠️ QR URL does not start with http/https: $qrUrl');
        // Still try to process it as the server might handle non-HTTP URLs
      }

      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Prepare API endpoint - using POST method as per API documentation
      final endpoint = '$baseUrl/ocr/order-no';

      // Prepare request body as JSON
      final requestBody = {
        'url': qrUrl, // Send raw URL without encoding in JSON body
      };

      debugPrint('🌐 API endpoint: $endpoint');
      debugPrint('📤 Request body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 QR Order API status: ${response.statusCode}');
      debugPrint('📡 QR Order API response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('✅ Successfully extracted order number from QR URL');
          return QrOrderResponse.fromJson(responseData);
        } else {
          debugPrint('❌ API returned unexpected response: ${response.body}');
          throw Exception(responseData['message'] ??
              'Failed to extract order number from QR URL');
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔒 Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        debugPrint('❌ Bad request: ${response.body}');
        throw Exception(responseData['message'] ?? 'Invalid QR URL format');
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        debugPrint('❌ Unprocessable Entity: ${response.body}');
        throw Exception(responseData['message'] ??
            'QR URL format tidak dapat diproses oleh server');
      } else {
        debugPrint(
            '❌ Failed to extract order number. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to extract order number: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error extracting order number from QR URL: $e');
      throw Exception('Error extracting: $e');
    }
  }

  /// Start delivery using order number
  Future<StartDeliveryResponse> startDelivery(String orderNo) async {
    try {
      debugPrint('🚀 Starting delivery for order: $orderNo');

      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/delivery'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'orderNo': orderNo,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📡 Start Delivery API status: ${response.statusCode}');
      debugPrint('📡 Start Delivery API response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('✅ Successfully started delivery');
          return StartDeliveryResponse.fromJson(responseData);
        } else {
          debugPrint('❌ API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to start delivery');
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔒 Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        debugPrint('❌ Bad request: ${response.body}');
        throw Exception(responseData['message'] ??
            'Invalid order number or order already started');
      } else if (response.statusCode == 404) {
        final responseData = json.decode(response.body);
        debugPrint('❌ Order not found: ${response.body}');
        throw Exception(responseData['message'] ?? 'Order not found');
      } else {
        debugPrint(
            '❌ Failed to start delivery. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to start delivery: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error starting delivery: $e');
      throw Exception('Error starting delivery: $e');
    }
  }

  /// Test API connectivity and endpoint availability
  Future<bool> testApiConnectivity() async {
    try {
      debugPrint('🔍 Testing API connectivity...');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No token available for connectivity test');
        return false;
      }

      // Test with a simple endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('📡 API Health check status: ${response.statusCode}');
      debugPrint('📡 API Health check response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ API connectivity test failed: $e');
      return false;
    }
  }

  /// Test different QR URL formats using POST method to troubleshoot 422 errors
  Future<void> testDifferentQrFormats(String originalQrUrl) async {
    debugPrint(
        '🧪 Testing QR URL format using POST method for: $originalQrUrl');

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('❌ No token available for format testing');
      return;
    }

    try {
      final endpoint = '$baseUrl/ocr/order-no';
      final requestBody = {
        'url': originalQrUrl,
      };

      debugPrint('🧪 Testing POST endpoint: $endpoint');
      debugPrint('🧪 Testing request body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('🧪 Test result: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ POST method working correctly');
      } else {
        debugPrint('❌ POST method failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🧪 POST test failed: $e');
    }
  }
}

/// Model for Qr Order Response
class QrOrderResponse {
  final String status;
  final String message;
  final QrOrderData data;

  QrOrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory QrOrderResponse.fromJson(Map<String, dynamic> json) {
    return QrOrderResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: QrOrderData.fromJson(json['data'] ?? {}),
    );
  }
}

class QrOrderData {
  final String? orderNo;
  final String? url;
  final String? extractedFrom;

  QrOrderData({
    this.orderNo,
    this.url,
    this.extractedFrom,
  });

  factory QrOrderData.fromJson(Map<String, dynamic> json) {
    return QrOrderData(
      orderNo: json['orderNo'],
      url: json['url'],
      extractedFrom: json['extractedFrom'],
    );
  }
}

/// Model for Start Delivery Response
class StartDeliveryResponse {
  final String status;
  final String message;
  final StartDeliveryData data;

  StartDeliveryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory StartDeliveryResponse.fromJson(Map<String, dynamic> json) {
    return StartDeliveryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: StartDeliveryData.fromJson(json['data'] ?? {}),
    );
  }
}

class StartDeliveryData {
  final String orderNo;
  final String driverId;
  final String customer;
  final String address;
  final List<String> itemsList;
  final double totalWeight;
  final double totalPrice;
  final String deliveryStatus;
  final String trackerId;
  final String deliveryStartTime;
  final String? checkInTime;
  final String? checkOutTime;
  final String lastUpdateTime;
  final String? orderNotes;

  StartDeliveryData({
    required this.orderNo,
    required this.driverId,
    required this.customer,
    required this.address,
    required this.itemsList,
    required this.totalWeight,
    required this.totalPrice,
    required this.deliveryStatus,
    required this.trackerId,
    required this.deliveryStartTime,
    this.checkInTime,
    this.checkOutTime,
    required this.lastUpdateTime,
    this.orderNotes,
  });

  factory StartDeliveryData.fromJson(Map<String, dynamic> json) {
    List<String> items = [];
    if (json['itemsList'] != null) {
      items = List<String>.from(json['itemsList']);
    }

    return StartDeliveryData(
      orderNo: json['orderNo'] ?? '',
      driverId: json['driverId'] ?? '',
      customer: json['customer'] ?? '',
      address: json['address'] ?? '',
      itemsList: items,
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      deliveryStatus: json['deliveryStatus'] ?? '',
      trackerId: json['trackerId'] ?? '',
      deliveryStartTime: json['deliveryStartTime'] ?? '',
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      lastUpdateTime: json['lastUpdateTime'] ?? '',
      orderNotes: json['orderNotes'],
    );
  }
}
