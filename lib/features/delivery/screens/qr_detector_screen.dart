import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../models/ocr_response_model.dart';
import 'add_package_confirmation.dart';

class QrDetectorScreen extends StatefulWidget {
  const QrDetectorScreen({Key? key}) : super(key: key);

  @override
  State<QrDetectorScreen> createState() => _QrDetectorScreenState();
}

class _QrDetectorScreenState extends State<QrDetectorScreen> {
  MobileScannerController? controller;
  String? detectedQrData;
  bool isDetecting = true;
  bool showTimeoutButton = false;
  Timer? timeoutTimer;
  final OcrService _ocrService = OcrService();
  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    // Start 5-second timeout
    _startTimeout();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _startTimeout() {
    timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && detectedQrData == null) {
        setState(() {
          showTimeoutButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Mobile scanner handles reassembly automatically
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (isDetecting && barcodeCapture.barcodes.isNotEmpty) {
      final String? code = barcodeCapture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          detectedQrData = code;
          isDetecting = false;
        });
        _handleQrDetected(code);
      }
    }
  }

  void _handleQrDetected(String qrData) {
    // Cancel timeout timer since QR was detected
    timeoutTimer?.cancel();

    // Stop camera
    controller?.stop();

    // Show detected QR data
    _showQrDetectedDialog(qrData);
  }

  void _showQrDetectedDialog(String qrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF306424).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF306424),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'QR Code Terdeteksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF306424),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Link yang terdeteksi:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  qrData,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Catatan: Backend belum mendukung pemrosesan link. Gunakan tombol "Ambil Foto" untuk melanjutkan dengan cara lama.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to home
              },
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _captureImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ambil Foto'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
                ),
                SizedBox(height: 20),
                Text("Membuka kamera..."),
              ],
            ),
          );
        },
      );

      // Capture image from camera
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (photo != null) {
        // Show processing dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF306424),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Memproses scan barcode..."),
                ],
              ),
            );
          },
        );

        String detectedPackageId = ""; // Default empty ID

        try {
          // Use OCR service to extract order number from barcode image
          final BarcodeScanResponse barcodeScanResponse =
              await _ocrService.getOrderNumberFromImage(File(photo.path));

          // Extract detected package ID from response
          detectedPackageId = barcodeScanResponse.data.orderNo ?? "";

          debugPrint(
              'Barcode scan successfully detected order number: $detectedPackageId');
        } catch (e) {
          debugPrint('Barcode scan processing error: $e');
          // We'll still continue even if barcode scan fails, user can input manually
        }

        // Close processing dialog
        if (context.mounted) Navigator.pop(context);

        // Navigate to package confirmation screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AddPackageConfirmationScreen(
                imagePath: photo.path,
                detectedPackageId: detectedPackageId,
              ),
            ),
          );
        }
      } else {
        // User cancelled camera
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pengambilan gambar dibatalkan"),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (context.mounted) {
        Navigator.of(context).pop(); // Close any open dialogs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // QR Camera View
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Scanning overlay frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF306424),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: -1,
                    left: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                          left: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                        ),
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(12)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                          right: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                        ),
                        borderRadius:
                            BorderRadius.only(topRight: Radius.circular(12)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                          left: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                        ),
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(12)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                          right: BorderSide(
                              color: const Color(0xFF306424), width: 6),
                        ),
                        borderRadius:
                            BorderRadius.only(bottomRight: Radius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top instruction text
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                detectedQrData != null
                    ? 'QR Code terdeteksi!'
                    : 'Arahkan kamera ke QR Code pada dokumen',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Bottom section with timeout button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showTimeoutButton && detectedQrData == null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'QR Code tidak terdeteksi setelah 5 detik',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _captureImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF306424),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: const Text(
                          'Ambil Foto Dokumen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else if (detectedQrData == null) ...[
                    // Show scanning indicator when no QR detected yet and timeout not reached
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF306424).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF306424)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF306424),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Mencari QR Code...',
                            style: TextStyle(
                              color: Color(0xFF306424),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
