import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType
import '../../auth/services/auth_service.dart';
import '../models/paddle_ocr_response_model.dart';

class PaddleOcrService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();

  /// Always use compute() to ensure UI never lags during image processing
  Future<File> _convertToJpg(File originalFile, {int quality = 85}) async {
    try {
      debugPrint(
          '🔄 Processing image to ensure JPG format: ${originalFile.path}');

      final fileSize = await originalFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      debugPrint('📊 Image size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Always use compute() to process image in background isolate
      // This ensures UI never lags regardless of image size
      final processedBytes = await compute(_processPaddleImageInIsolate, {
        'filePath': originalFile.path,
        'quality': quality,
        'maxDimension': 2048,
      });

      if (processedBytes == null) {
        throw Exception('Failed to process image');
      }

      // Save to a new file in temp directory
      final tempDir = await getTemporaryDirectory();
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_paddle.jpg';
      final targetPath = path.join(tempDir.path, uniqueFileName);

      final newFile = await File(targetPath).writeAsBytes(processedBytes);
      debugPrint(
          '✅ Image successfully processed and saved as JPG: $targetPath');
      debugPrint('📊 Size: ${processedBytes.length} bytes');

      return newFile;
    } catch (e) {
      debugPrint('❌ Error converting image to JPG: $e, using original file');
      return originalFile;
    }
  }

  /// Process delivery order image using Paddle OCR
  Future<PaddleOcrResponse> processReturnItemsWithPaddle({
    required List<File> images,
    required String orderNo,
  }) async {
    List<File> convertedImages = [];

    try {
      debugPrint('🏓 Processing images with Paddle OCR for order: $orderNo');
      debugPrint('📸 Number of images: ${images.length}');

      // Get token using AuthService
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      } // Convert all images to JPG format
      debugPrint('🔄 Converting images to JPG format...');
      for (int i = 0; i < images.length; i++) {
        try {
          debugPrint(
              '🔄 Converting image ${i + 1}/${images.length}: ${images[i].path}');
          final convertedImage = await _convertToJpg(images[i]);
          convertedImages.add(convertedImage);
          debugPrint(
              '✅ Converted image ${i + 1}/${images.length} successfully');
        } catch (conversionError) {
          debugPrint(
              '❌ Failed to convert image ${i + 1}/${images.length}: $conversionError');
          throw Exception('Failed to convert image ${i + 1}: $conversionError');
        }
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/ocr/return-item-db');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] =
          'application/json'; // Add orderNo to the form data
      request.fields['orderNo'] = orderNo;
      debugPrint('📤 Added orderNo field: $orderNo');

      // Add converted images to the form data
      for (int i = 0; i < convertedImages.length; i++) {
        final file = convertedImages[i];

        // Verify file exists and is readable
        if (!await file.exists()) {
          throw Exception('Converted image file not found: ${file.path}');
        }
        // Read file bytes to verify it's not corrupted
        final fileBytes = await file.readAsBytes();
        if (fileBytes.isEmpty) {
          throw Exception('Image file is empty: ${file.path}');
        }

        // Create multipart file with explicit content type like the working services
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();

        final multipartFile = http.MultipartFile(
          'images', // Keep using 'images' as the API expects this field name
          fileStream,
          fileLength,
          filename: path.basename(
              file.path), // Use actual filename instead of generic name
          contentType: MediaType('image', 'jpeg'), // Explicit content type
        );
        request.files.add(multipartFile);

        debugPrint(
            '📎 Added file: ${path.basename(file.path)} (${fileBytes.length} bytes)');
        debugPrint('📎 File path: ${file.path}');
        debugPrint('📎 Multipart field name: images');
        debugPrint('📎 Filename: ${path.basename(file.path)}');
      }
      debugPrint('🌐 Paddle OCR API endpoint: $uri');
      debugPrint('📤 Order number: $orderNo');
      debugPrint('📤 Images count: ${request.files.length}');
      debugPrint('📤 Request headers: ${request.headers}');
      debugPrint('📤 Request fields: ${request.fields}');

      // Debug each file in detail
      for (int i = 0; i < request.files.length; i++) {
        final file = request.files[i];
        debugPrint(
            '📎 File $i: field="${file.field}", filename="${file.filename}", contentType="${file.contentType}"');
      }

      // Verify the exact form data structure
      debugPrint('🔍 Form-data structure verification:');
      debugPrint('  - Field "orderNo": "${request.fields['orderNo']}"');
      debugPrint('  - Field "images": ${request.files.length} file(s)');
      request.files.forEach((file) {
        debugPrint('    * ${file.filename} (field: ${file.field})');
      });

      // Send request with timeout
      debugPrint('📡 Sending request to Paddle OCR API...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120), // Longer timeout for OCR processing
        onTimeout: () {
          debugPrint('⏰ Request timeout after 120 seconds');
          throw Exception('Request timeout. Please try again.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Paddle OCR API status: ${response.statusCode}');
      debugPrint('📡 Paddle OCR API response length: ${response.body.length}');

      // Log response body (truncated if too long)
      if (response.body.length > 1000) {
        debugPrint(
            '📡 Paddle OCR API response (truncated): ${response.body.substring(0, 1000)}...');
      } else {
        debugPrint('📡 Paddle OCR API response: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          if (responseData['status'] == 'success' &&
              responseData['data'] != null) {
            debugPrint('✅ Successfully processed images with Paddle OCR');
            debugPrint('📊 Response data keys: ${responseData.keys.toList()}');
            return PaddleOcrResponse.fromJson(responseData);
          } else {
            debugPrint('❌ API returned unexpected response structure');
            debugPrint('📊 Response status: ${responseData['status']}');
            debugPrint('📊 Response message: ${responseData['message']}');
            throw Exception(responseData['message'] ??
                'Failed to process images with Paddle OCR');
          }
        } catch (e) {
          debugPrint('❌ Error parsing JSON response: $e');
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔒 Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        try {
          final responseData = json.decode(response.body);
          debugPrint('❌ Bad request: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Invalid request parameters');
        } catch (e) {
          throw Exception('Bad request: ${response.statusCode}');
        }
      } else if (response.statusCode == 422) {
        try {
          final responseData = json.decode(response.body);
          debugPrint('❌ Unprocessable Entity: ${response.body}');
          throw Exception(responseData['message'] ??
              'Unable to process the provided images');
        } catch (e) {
          throw Exception('Unable to process images: ${response.statusCode}');
        }
      } else if (response.statusCode == 500) {
        debugPrint('🚨 Server error: ${response.body}');
        throw Exception('Server error. Please try again later.');
      } else {
        debugPrint(
            '❌ Failed to process images. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to process images: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error processing images with Paddle OCR: $e');
      if (e is http.ClientException || e.toString().contains('timeout')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      rethrow;
    } finally {
      // Clean up converted image files
      try {
        for (final file in convertedImages) {
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Cleaned up converted file: ${file.path}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Warning: Could not clean up converted files: $e');
      }
    }
  }

  /// Test Paddle OCR API connectivity
  Future<bool> testPaddleOcrConnectivity() async {
    try {
      debugPrint('🔍 Testing Paddle OCR API connectivity...');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No token available for connectivity test');
        return false;
      }

      // Test with a simple health check endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 API Health check status: ${response.statusCode}');
      debugPrint('📡 API Health check response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Paddle OCR API connectivity test failed: $e');
      return false;
    }
  }

  /// Test method to verify form-data structure manually
  Future<Map<String, dynamic>> testFormDataStructure({
    required File imageFile,
    required String orderNo,
  }) async {
    try {
      debugPrint('🧪 Testing form-data structure for Paddle OCR API');

      // Get token
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Convert image to JPG
      final convertedImage = await _convertToJpg(imageFile);

      // Create multipart request
      final uri = Uri.parse('$baseUrl/ocr/return-item-db');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['orderNo'] = orderNo;

      // Add image file
      final multipartFile = await http.MultipartFile.fromPath(
        'images',
        convertedImage.path,
        filename: 'document.jpg',
      );
      request.files.add(multipartFile);

      // Log the exact structure
      debugPrint('🔍 EXACT FORM-DATA STRUCTURE:');
      debugPrint('  URL: $uri');
      debugPrint('  Method: POST');
      debugPrint('  Headers: ${request.headers}');
      debugPrint('  Fields: ${request.fields}');
      debugPrint('  Files:');
      for (var file in request.files) {
        debugPrint('    - Field: "${file.field}"');
        debugPrint('    - Filename: "${file.filename}"');
        debugPrint('    - ContentType: "${file.contentType}"');
        debugPrint('    - Length: ${file.length}');
      }

      // Send request
      debugPrint('📡 Sending test request...');
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📡 Response Headers: ${response.headers}');
      debugPrint('📡 Response Body: ${response.body}');

      return {
        'statusCode': response.statusCode,
        'headers': response.headers,
        'body': response.body,
        'success': response.statusCode == 200,
      };
    } catch (e) {
      debugPrint('❌ Test failed: $e');
      return {
        'error': e.toString(),
        'success': false,
      };
    }
  }
}

// Static function to process image in isolate - prevents UI lag
List<int>? _processPaddleImageInIsolate(Map<String, dynamic> params) {
  try {
    final String filePath = params['filePath'];
    final int quality = params['quality'];
    final int maxDimension = params['maxDimension'] ?? 2048;

    // Read the image file
    final bytes = File(filePath).readAsBytesSync();

    // Decode the image using the image package
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      return null;
    }

    // Resize if too large
    img.Image resizedImage = decodedImage;
    if (decodedImage.width > maxDimension ||
        decodedImage.height > maxDimension) {
      if (decodedImage.width > decodedImage.height) {
        resizedImage = img.copyResize(decodedImage, width: maxDimension);
      } else {
        resizedImage = img.copyResize(decodedImage, height: maxDimension);
      }
    }

    // Create a new JPG image with proper encoding
    final jpgBytes = img.encodeJpg(resizedImage, quality: quality);

    return jpgBytes;
  } catch (e) {
    debugPrint('Error processing image in isolate: $e');
    return null;
  }
}
