import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
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
      request.fields['reason'] =
          reason; // Convert returnItems list to JSON string with proper format expected by API
      final List<Map<String, dynamic>> formattedItems = returnItems.map((item) {
        return {
          "name": item['name'],
          "quantity": item['returnQty'] ??
              item['qty'], // Use return quantity if available
          "unit_metrics": item['unitMetrics'] ?? "kg", // Try snake_case
        };
      }).toList();

      request.fields['returnItems'] = jsonEncode(formattedItems);

      // Add notes if provided
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      } // Add image files with proper MIME type and processing
      for (int i = 0; i < images.length; i++) {
        final file = images[i];

        // Process and ensure the file is in proper JPG format
        File processedFile = await _ensureJpgFile(file);
        debugPrint('Using processed file: ${processedFile.path}');

        final fileStream = http.ByteStream(processedFile.openRead());
        final fileLength = await processedFile.length();

        final multipartFile = http.MultipartFile(
          'images',
          fileStream,
          fileLength,
          filename: path.basename(processedFile.path),
          contentType: MediaType('image', 'jpeg'),
        );

        request.files.add(multipartFile);
        debugPrint(
            'Added image file: ${multipartFile.filename} with content type: ${multipartFile.contentType}, size: $fileLength bytes');
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
  } // Always use compute() to ensure UI never lags during image processing

  Future<File> _ensureJpgFile(File originalFile) async {
    try {
      debugPrint('Processing image to ensure proper format...');

      final fileSize = await originalFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      debugPrint('Image size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Always use compute() to process image in background isolate
      // This ensures UI never lags regardless of image size
      final processedBytes = await compute(_processReturnImageInIsolate, {
        'filePath': originalFile.path,
        'quality': 85,
      });

      if (processedBytes == null) {
        throw Exception('Failed to process image');
      }

      // Save to a new file in temp directory
      final tempDir = await getTemporaryDirectory();
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(originalFile.path)}';
      final targetPath =
          path.join(tempDir.path, uniqueFileName.replaceAll('.', '') + '.jpg');

      final newFile = await File(targetPath).writeAsBytes(processedBytes);
      debugPrint('Image successfully processed and saved as JPG');

      return newFile;
    } catch (e) {
      debugPrint('Error converting image to JPG: $e, using original file');
      return originalFile;
    }
  }
}

// Static function to process return image in isolate - prevents UI lag
List<int>? _processReturnImageInIsolate(Map<String, dynamic> params) {
  try {
    final String filePath = params['filePath'];
    final int quality = params['quality'];

    // Read the image file
    final bytes = File(filePath).readAsBytesSync();

    // Decode the image using the image package
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      return null;
    }

    // Create a new JPG image with proper encoding
    final jpgBytes = img.encodeJpg(decodedImage, quality: quality);

    return jpgBytes;
  } catch (e) {
    debugPrint('Error processing return image in isolate: $e');
    return null;
  }
}
