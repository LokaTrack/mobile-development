import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/start_delivery_service.dart';
import '../services/ocr_service.dart';

class AddPackageConfirmationScreen extends StatefulWidget {
  final String imagePath;
  final String detectedPackageId;

  const AddPackageConfirmationScreen({
    Key? key,
    required this.imagePath,
    required this.detectedPackageId,
  }) : super(key: key);

  @override
  State<AddPackageConfirmationScreen> createState() =>
      _AddPackageConfirmationScreenState();
}

class _AddPackageConfirmationScreenState
    extends State<AddPackageConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _packageIdController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isProcessing = false;
  bool _showFullDocumentImage =
      false; // New variable for full screen image view
  late String _currentImagePath; // Track current image path
  bool _isOcrProcessing = false; // Track OCR processing state

  // Add services
  final StartDeliveryService _startDeliveryService = StartDeliveryService();
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _packageIdController = TextEditingController(
      text: widget.detectedPackageId,
    );
    _setupAnimations();

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _packageIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Tambah Paket',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF306424),
            ),
          ),
          content: Text(
            'Apakah Anda yakin menambahkan paket dengan ID ${_packageIdController.text}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addPackage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ya, Tambahkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPackage() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    // Validasi ID paket
    if (_packageIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Paket tidak boleh kosong!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Tampilkan loading state
    setState(() {
      _isProcessing = true;
    });

    try {
      // Panggil API start delivery
      final response = await _startDeliveryService
          .startDelivery(_packageIdController.text.trim());

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Tampilkan pesan sukses dan navigasi kembali ke halaman home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: const Color(0xFF306424),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Kembali ke halaman home dengan refresh data
        Navigator.of(context).pop(
            true); // Pass true to indicate success for refreshing home screen
      }
    } catch (e) {
      // Penanganan error
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // New method to take a new photo
  Future<void> _captureNewPhoto() async {
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

      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (photo != null) {
        setState(() {
          _currentImagePath = photo.path;
          _isOcrProcessing = true;
        });

        // Process the new image with OCR
        await _processImageWithOcr(File(photo.path));
      }
    } catch (e) {
      // Close loading dialog if there was an error
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to process image with barcode scanning
  Future<void> _processImageWithOcr(File imageFile) async {
    try {
      final barcodeScanResponse =
          await _ocrService.getOrderNumberFromImage(imageFile);

      if (!mounted) return;

      // Extract order number from barcode scan result and update text field
      if (barcodeScanResponse.data.orderNo != null &&
          barcodeScanResponse.data.orderNo!.isNotEmpty) {
        setState(() {
          _packageIdController.text = barcodeScanResponse.data.orderNo!;
          _isOcrProcessing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Paket berhasil dideteksi dari QR Code'),
            backgroundColor: Color(0xFF306424),
          ),
        );
      } else {
        setState(() {
          _isOcrProcessing = false;
        }); // Show message that no ID was detected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak dapat mendeteksi QR Code. Silakan masukkan ID secara manual.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isOcrProcessing = false;
      }); // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error saat memproses QR Code: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _retakePhoto() {
    _captureNewPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Konfirmasi Paket',
          style: TextStyle(
            color: Color(0xFF306424),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF306424)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          // Background decorations
          _buildBackgroundDecorations(size),

          // Main content with ScrollView
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Instruction text
                      Text(
                        'Verifikasi data paket yang terdeteksi:',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Image preview card
                      _buildImagePreview(),

                      const SizedBox(height: 24),

                      // Package ID field
                      _buildPackageIdField(),

                      const SizedBox(height: 32),

                      // Buttons
                      _buildActionButtons(),

                      // Add padding at bottom to ensure content doesn't get hidden behind keyboard
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).viewInsets.bottom
                            : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
                ),
              ),
            ),

          // Full screen document image viewer - new feature
          if (_showFullDocumentImage) _buildFullScreenDocumentViewer(),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations(Size size) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Bottom left circle
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Small accent circle
        Positioned(
          left: size.width * 0.2,
          top: size.height * 0.15,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF306424).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF306424),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Gambar Dokumen',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),

                // View document button - new feature
                InkWell(
                  onTap: () {
                    setState(() {
                      _showFullDocumentImage = true;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF306424).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.fullscreen,
                          size: 14,
                          color: Color(0xFF306424),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Lihat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF306424),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),

          // Image content with portrait ratio instead of landscape
          GestureDetector(
            onTap: () {
              setState(() {
                _showFullDocumentImage = true;
              });
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4, // Changed to portrait ratio (3:4) from 16:9
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Using _currentImagePath instead of widget.imagePath for the image
                    Image.file(File(_currentImagePath), fit: BoxFit.cover),

                    // OCR Processing Indicator overlay
                    if (_isOcrProcessing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Memproses OCR...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Document Label
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: const Text(
                          'Dokumen Delivery Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New method for full screen document viewer
  Widget _buildFullScreenDocumentViewer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFullDocumentImage = false;
        });
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Document image - use _currentImagePath instead of widget.imagePath
            Center(
              child: InteractiveViewer(
                child: Image.file(File(_currentImagePath)),
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

            // Info at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Dokumen Delivery Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pinch untuk zoom, tap untuk tutup',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ID Paket Terdeteksi',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _packageIdController,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  // Clear text field
                  _packageIdController.clear();
                },
                icon: const Icon(Icons.clear, color: Colors.grey),
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.qr_code, color: Color(0xFF306424)),
              ),
              hintText: 'Masukkan ID Paket jika tidak terdeteksi',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Koreksi ID paket jika hasil deteksi tidak akurat',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Retake photo button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _retakePhoto,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF306424),
              elevation: 0,
              side: BorderSide(
                color: const Color(0xFF306424).withValues(alpha: 0.3),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: const Text(
              'Ambil Ulang',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Confirm button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _packageIdController.text.isEmpty
                ? null
                : _showConfirmationDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF306424),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: const Color(0xFF306424).withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Konfirmasi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
