import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../../auth/services/auth_service.dart';
import '../models/ocr_response_model.dart';
import 'dart:convert';

class OcrService {
  final String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthService _authService = AuthService();
  Future<BarcodeScanResponse> getOrderNumberFromImage(File imageFile) async {
    try {
      debugPrint('Starting barcode scan process with file: ${imageFile.path}');

      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Process and encode image to ensure it's a proper JPG
      File processedFile = await _ensureJpgFile(imageFile);
      debugPrint('Using processed file: ${processedFile.path}');

      // Create request with proper content type headers
      final uri = Uri.parse('$baseUrl/ocr/scan-barcode');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file with explicit content type
      final fileStream = http.ByteStream(processedFile.openRead());
      final fileLength = await processedFile.length();

      final multipartFile = http.MultipartFile(
        'image', // Field name expected by API
        fileStream,
        fileLength,
        filename: path.basename(processedFile.path),
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile); // Log request details for debugging
      debugPrint(
          'Sending barcode scan request with file: ${multipartFile.filename}, size: $fileLength bytes');
      debugPrint('Content-Type: ${multipartFile.contentType}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Barcode scan API status: ${response.statusCode}');
      debugPrint('Barcode scan API response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully processed barcode image');
          final barcodeScanResponse =
              BarcodeScanResponse.fromJson(responseData);

          // Print extracted order number for debugging
          debugPrint(
              'Extracted Order Number: ${barcodeScanResponse.data.orderNo}');
          debugPrint('Extracted URL: ${barcodeScanResponse.data.url}');

          return barcodeScanResponse;
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(
              responseData['message'] ?? 'Failed to process barcode image');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
            'Failed to process barcode image. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to process barcode image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error processing barcode image: $e');
      throw Exception('Error processing barcode image: $e');
    }
  }

  Future<ReturnItemOcrResponse> getReturnItemsFromImage(File imageFile) async {
    try {
      debugPrint(
          'Starting Return Item OCR process with file: ${imageFile.path}');

      // Get token using AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Process and encode image to ensure it's a proper JPG
      File processedFile = await _ensureJpgFile(imageFile);
      debugPrint('Using processed file: ${processedFile.path}');

      // Create request with proper content type headers
      final uri = Uri.parse('$baseUrl/ocr/return-item');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file with explicit content type
      final fileStream = http.ByteStream(processedFile.openRead());
      final fileLength = await processedFile.length();

      final multipartFile = http.MultipartFile(
        'images', // Changed from 'image' to 'images' - This is what the API expects
        fileStream,
        fileLength,
        filename: path.basename(processedFile.path),
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Log request details for debugging
      debugPrint(
          'Sending Return Item OCR request with file: ${multipartFile.filename}, size: $fileLength bytes');
      debugPrint('Content-Type: ${multipartFile.contentType}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Return Item OCR API status: ${response.statusCode}');
      debugPrint('Return Item OCR API response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          debugPrint('Successfully processed return item document image');
          final returnItemResponse =
              ReturnItemOcrResponse.fromJson(responseData);

          // Print extracted items for debugging
          debugPrint(
              'Extracted ${returnItemResponse.data.itemsData.length} return items');

          return returnItemResponse;
        } else {
          debugPrint('API returned unexpected response: ${response.body}');
          throw Exception(responseData['message'] ??
              'Failed to process return document image');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized. Token might be expired.');
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
            'Failed to process return document image. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to process return document image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error processing return document image: $e');
      throw Exception('Error processing return document image: $e');
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
      final processedBytes = await compute(_processImageInIsolate, {
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

// Static function to process image in isolate - prevents UI lag
List<int>? _processImageInIsolate(Map<String, dynamic> params) {
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
    debugPrint('Error processing image in isolate: $e');
    return null;
  }
}
