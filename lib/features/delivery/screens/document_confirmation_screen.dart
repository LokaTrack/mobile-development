import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/package.dart';
import '../models/ocr_response_model.dart';
import '../models/paddle_ocr_response_model.dart';
import '../services/ocr_service.dart';
import '../services/paddle_ocr_service.dart';
import 'return_confirmation_screen.dart';

class DocumentConfirmationScreen extends StatefulWidget {
  final String deliveryId;
  final List<File> capturedImages;
  final Package? package; // Parameter opsional
  final String? returnReason;
  final String? notes;

  const DocumentConfirmationScreen({
    Key? key,
    required this.deliveryId,
    required this.capturedImages,
    this.package,
    this.returnReason,
    this.notes,
  }) : super(key: key);

  @override
  State<DocumentConfirmationScreen> createState() =>
      _DocumentConfirmationScreenState();
}

class _DocumentConfirmationScreenState
    extends State<DocumentConfirmationScreen> {
  late List<File> _capturedImages;
  bool _isSubmitting = false;
  int _currentIndex = 0; // Untuk menampilkan indikator halaman aktif
  final OcrService _ocrService = OcrService();
  final PaddleOcrService _paddleOcrService = PaddleOcrService();

  @override
  void initState() {
    super.initState();
    _capturedImages = List.from(widget.capturedImages);
  }

  Future<void> _captureAdditionalImage() async {
    try {
      final ImagePicker picker = ImagePicker();

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

      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Tutup loading dialog
      if (context.mounted) Navigator.pop(context);

      if (photo != null) {
        setState(() {
          _capturedImages.add(File(photo.path));
          _currentIndex = _capturedImages.length - 1; // Fokus ke gambar baru
        });
      }
    } catch (e) {
      // Tutup loading dialog jika terjadi error
      if (context.mounted) Navigator.pop(context);

      // Tampilkan pesan error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    if (_capturedImages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setidaknya harus ada satu foto dokumen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _capturedImages.removeAt(index);
      _currentIndex = _currentIndex >= _capturedImages.length
          ? _capturedImages.length - 1
          : _currentIndex;
    });
  }

  void _nextImage() {
    if (_currentIndex < _capturedImages.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _submitImagesWithPaddle() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ambil minimal satu foto dokumen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      // Process all document images with Paddle OCR to extract return items
      PaddleOcrResponse? paddleResponse;
      String? paddleError;

      try {
        debugPrint('Processing document images with Paddle OCR...');
        paddleResponse = await _paddleOcrService.processReturnItemsWithPaddle(
          images: _capturedImages,
          orderNo: widget.package?.id ?? widget.deliveryId,
        );
        debugPrint(
            'Paddle OCR processing complete. Found ${paddleResponse.data.returnItems.length} return items.');
      } catch (e) {
        paddleError = e.toString();
        debugPrint('Error processing Paddle OCR: $e');

        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Gagal memproses dengan Paddle OCR: ${_getSimplifiedErrorMessage(paddleError)}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // Continue with the navigation but send empty results if OCR fails
      } // Prepare the OCR results map with the returned items and all captured images
      final Map<String, dynamic> ocrResults = {
        'allCapturedImages': _capturedImages.map((file) => file.path).toList(),
        'hasOcrProcessing':
            true, // Flag to indicate OCR processing was attempted
        'paddleOcrUsed': true, // Flag to indicate Paddle OCR was used
        'ocrError': paddleError, // Include detailed error if any
        'ocrSuccess': paddleResponse != null, // Flag for success status
      }; // If Paddle OCR was successful, convert the response to compatible format
      if (paddleResponse != null) {
        final returnedItems = paddleResponse.data.returnItems.map((item) {
          debugPrint(
              'Paddle OCR Item Debug: name=${item.name}, quantity=${item.quantity}, returnQuantity=${item.returnQuantity}, unitPrice=${item.unitPrice}');
          return {
            'id': item.no.toString(), // Use 'no' field as ID
            'name': item.name,
            'returnQuantity': item.returnQuantity,
            'returnQty': item.returnQuantity, // Add for UI compatibility
            'reason': '', // Default empty reason
            'autoChecked':
                item.returnQuantity > 0, // Auto-check if return quantity > 0
            'confidence': 1.0, // High confidence for Paddle OCR
            'source': 'paddle_ocr', // Add source identifier
            'weight': item.weight,
            'unitPrice': item.unitPrice,
            'price': item.unitPrice, // Add for UI compatibility
            'total': item.total,
            'quantity': item.quantity,
            'qty': item.quantity, // Add for UI compatibility
            'ocrQuantity': item.ocrQuantity,
            'ocrItemName': item.ocrItemName,
            'formattedItemText': item.formattedItemText,
            'formattedPrice': item.formattedPrice,
            'formattedTotal': item.formattedTotal,
            'unitMetrics': item.unitMetrics,
          };
        }).toList();

        debugPrint(
            'Paddle OCR final returnedItems count: ${returnedItems.length}');
        debugPrint(
            'Paddle OCR first item (if exists): ${returnedItems.isNotEmpty ? returnedItems.first : 'No items'}');

        ocrResults['returnedItems'] = returnedItems;
        ocrResults['noItemsFound'] = returnedItems.isEmpty;
        ocrResults['matchedItems'] = paddleResponse.data.matchedItems
            .map((item) => item.toMap())
            .toList();
        ocrResults['processingTime'] = paddleResponse.data.processingTime;
        ocrResults['allText'] = paddleResponse.data.allText;
      } else {
        // If Paddle OCR failed completely, provide an empty list
        ocrResults['returnedItems'] = [];
      }

      if (mounted) {
        // Navigate to ReturnConfirmationScreen with the Paddle OCR results
        if (widget.package != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReturnConfirmationScreen(
                package: widget.package!,
                imagePath:
                    _capturedImages.first.path, // For backward compatibility
                returnReason: widget.returnReason ?? 'Barang tidak sesuai',
                notes: widget.notes ?? '',
                ocrResults: ocrResults,
              ),
            ),
          );
        } else {
          // If no package is provided (which shouldn't happen since we always pass a package object)
          // We'll fetch the package details from API in a real app
          // But for now, create a package with at least the ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReturnConfirmationScreen(
                package: Package(
                  id: widget.deliveryId,
                  recipient:
                      "Data tidak tersedia", // Use generic message instead of "Customer"
                  address:
                      "Data tidak tersedia", // Use generic message instead of "Address"
                  status: PackageStatus.checkin,
                  items: "Items",
                  scheduledDelivery: DateTime.now(),
                  totalAmount: 0,
                  weight: 0,
                  notes: '',
                ),
                imagePath: _capturedImages.first.path,
                returnReason: 'Barang tidak sesuai',
                notes: '',
                ocrResults: ocrResults,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Paddle OCR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getSimplifiedErrorMessage(String? errorMessage) {
    if (errorMessage == null) return 'Terjadi kesalahan tidak diketahui';

    if (errorMessage.contains('timeout') ||
        errorMessage.contains('Network error')) {
      return 'Koneksi timeout, coba lagi';
    } else if (errorMessage.contains('Session expired') ||
        errorMessage.contains('401')) {
      return 'Sesi habis, silakan login kembali';
    } else if (errorMessage.contains('Server error') ||
        errorMessage.contains('500')) {
      return 'Server bermasalah, coba lagi nanti';
    } else if (errorMessage.contains('Unable to process') ||
        errorMessage.contains('422')) {
      return 'Format gambar tidak sesuai';
    } else if (errorMessage.contains('No access token')) {
      return 'Token akses tidak ditemukan';
    } else if (errorMessage.contains('Invalid response format')) {
      return 'Response server tidak valid';
    } else {
      return 'Gagal memproses gambar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
          0xFFF8FAF5), // Sesuaikan dengan background Color pada screen lain
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Dokumen',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF306424),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Memproses dokumen...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header Section with Nice Design
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF306424)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Color(0xFF306424),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Halaman Dokumen (${_capturedImages.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF306424),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(
                          'Tinjau dokumen yang telah difoto. Tambahkan halaman jika dokumen memiliki beberapa halaman.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Document Preview Section with Pagination
                Expanded(
                  child: _capturedImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 60,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada dokumen yang difoto',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Image Preview with Navigation Controls
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Document Image
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          _capturedImages[_currentIndex],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),

                                    // Gradient overlay at the bottom for page indicators
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black
                                                  .withValues(alpha: 0.5),
                                            ],
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Halaman ${_currentIndex + 1} dari ${_capturedImages.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Previous button
                                    if (_capturedImages.length > 1 &&
                                        _currentIndex > 0)
                                      Positioned(
                                        left: 8,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Material(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: InkWell(
                                              onTap: _previousImage,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.chevron_left,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Next button
                                    if (_capturedImages.length > 1 &&
                                        _currentIndex <
                                            _capturedImages.length - 1)
                                      Positioned(
                                        right: 8,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Material(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: InkWell(
                                              onTap: _nextImage,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Delete button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(20),
                                        child: InkWell(
                                          onTap: () =>
                                              _removeImage(_currentIndex),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Page indicator dots
                              if (_capturedImages.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _capturedImages.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: index == _currentIndex
                                              ? const Color(0xFF306424)
                                              : Colors.grey
                                                  .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ), // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Tambah Halaman button
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_a_photo, size: 18),
                            label: const Text('Tambah Halaman'),
                            onPressed: _captureAdditionalImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF306424),
                              side: const BorderSide(color: Color(0xFF306424)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Scan OCR button (using Paddle OCR)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.document_scanner, size: 18),
                            label: const Text('Scan OCR'),
                            onPressed: _submitImagesWithPaddle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF306424),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
