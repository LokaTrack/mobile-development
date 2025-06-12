import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_api_service.dart';
import 'home_screen.dart';

class QrDetectorScreen extends StatefulWidget {
  const QrDetectorScreen({Key? key}) : super(key: key);

  @override
  State<QrDetectorScreen> createState() => _QrDetectorScreenState();
}

class _QrDetectorScreenState extends State<QrDetectorScreen> {
  MobileScannerController? controller;
  String? detectedQrData;
  bool isDetecting = true;
  final QrApiService _qrApiService = QrApiService();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Mobile scanner handles reassembly automatically
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (isDetecting && !isProcessing && barcodeCapture.barcodes.isNotEmpty) {
      final String? code = barcodeCapture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          detectedQrData = code;
          isDetecting = false;
          isProcessing = true;
        });
        _handleQrDetected(code);
      }
    }
  }

  void _handleQrDetected(String qrData) async {
    // Stop camera
    controller?.stop();

    try {
      // Show processing dialog
      _showProcessingDialog();

      // Call API to extract order number from QR URL
      final qrResponse = await _qrApiService.getOrderNumberFromUrl(qrData);
      final orderNo = qrResponse.data.orderNo;

      // Close processing dialog
      if (mounted) Navigator.pop(context);

      if (orderNo != null && orderNo.isNotEmpty) {
        // Show confirmation dialog with extracted order number
        _showOrderConfirmationDialog(orderNo, qrData);
      } else {
        _showErrorDialog('Nomor order tidak ditemukan dalam QR code');
      }
    } catch (e) {
      // Close processing dialog
      if (mounted) Navigator.pop(context);

      String errorMessage = 'Error mengekstrak nomor order: ${e.toString()}';

      // Provide more specific error messages for common issues
      if (e.toString().contains('422')) {
        errorMessage =
            'Format QR code tidak valid atau tidak dapat diproses server';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Sesi login expired, silakan login ulang';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Format QR URL tidak valid';
      } else if (e.toString().contains('No access token')) {
        errorMessage = 'Token akses tidak ditemukan, silakan login ulang';
      }

      debugPrint('❌ QR Processing Error: ${e.toString()}');
      _showErrorDialog(errorMessage);
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF306424).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Memproses QR Code...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mengekstrak nomor order dari URL',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderConfirmationDialog(String orderNo, String qrUrl) {
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
                  color: const Color(0xFF306424).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF306424),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Pengiriman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF306424),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nomor Order yang ditemukan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF306424).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF306424).withValues(alpha: 0.3)),
                ),
                child: Text(
                  orderNo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF306424),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Yakin ingin memulai pengiriman untuk order ini?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _restartScanning();
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startDelivery(orderNo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Mulai Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startDelivery(String orderNo) async {
    try {
      // Show loading dialog
      _showLoadingDialog('Memulai pengiriman...');

      // Call API to start delivery
      final deliveryResponse = await _qrApiService.startDelivery(orderNo);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      _showSuccessDialog(orderNo, deliveryResponse);
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      _showErrorDialog('Gagal memulai pengiriman: ${e.toString()}');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String orderNo, StartDeliveryResponse response) {
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
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pengiriman Dimulai!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ${response.data.orderNo} berhasil dimulai',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Pelanggan:', response.data.customer),
                    const SizedBox(height: 4),
                    _buildInfoRow('Alamat:', response.data.address),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                        'Total Berat:', '${response.data.totalWeight} kg'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Total Harga:',
                        'Rp ${response.data.totalPrice.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to HomeScreen and remove all previous routes to ensure fresh data load
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Kembali ke Home',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
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
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _restartScanning();
              },
              child: const Text('Scan Ulang'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to HomeScreen and remove all previous routes to ensure fresh data load
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Kembali'),
            ),
          ],
        );
      },
    );
  }

  void _restartScanning() {
    setState(() {
      isDetecting = true;
      isProcessing = false;
      detectedQrData = null;
    });
    controller?.start();
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
                  color: isProcessing ? Colors.orange : const Color(0xFF306424),
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
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                          left: BorderSide(
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                        ),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12)),
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
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                          right: BorderSide(
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                        ),
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12)),
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
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                          left: BorderSide(
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                        ),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12)),
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
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                          right: BorderSide(
                              color: isProcessing
                                  ? Colors.orange
                                  : const Color(0xFF306424),
                              width: 6),
                        ),
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(12)),
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
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isProcessing
                    ? 'Memproses QR Code...'
                    : detectedQrData != null
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

          // Bottom instruction
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
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isProcessing && detectedQrData == null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF306424).withValues(alpha: 0.2),
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
                  ] else if (isProcessing) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
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
                                Colors.orange,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Sedang memproses...',
                            style: TextStyle(
                              color: Colors.orange,
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
