import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/package.dart';
import '../services/ocr_service.dart';
import '../models/ocr_response_model.dart';
import '../services/return_delivery_service.dart';

class ReturnConfirmationScreen extends StatefulWidget {
  final Package package;
  final String imagePath;
  final String returnReason;
  final String notes;
  final Map<String, dynamic> ocrResults;

  const ReturnConfirmationScreen({
    Key? key,
    required this.package,
    required this.imagePath,
    required this.returnReason,
    required this.notes,
    required this.ocrResults,
  }) : super(key: key);

  @override
  State<ReturnConfirmationScreen> createState() =>
      _ReturnConfirmationScreenState();
}

class _ReturnConfirmationScreenState extends State<ReturnConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isSubmitting = false;
  bool _showFullDocumentImage = false;
  int _currentDocumentIndex = 0; // Untuk tracking halaman dokumen yang aktif
  bool _isProcessingDocument = false;

  final List<Map<String, dynamic>> _returnedItems = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OcrService _ocrService = OcrService();

  // Untuk menyimpan semua path file gambar dokumen
  late List<String> _documentPaths = [];

  // Add a variable to store the editable notes
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _processDocumentWithOcr();

    // Initialize the notes controller with the value from the previous screen
    _notesController = TextEditingController(text: widget.notes);

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize document paths from ocrResults if available
    if (widget.ocrResults.containsKey('allCapturedImages')) {
      _documentPaths =
          List<String>.from(widget.ocrResults['allCapturedImages']);
    } else {
      // Fallback to the single imagePath if allCapturedImages is not available
      _documentPaths = [widget.imagePath];
    }
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

    _animationController.forward();
  }

  // Process document with OCR to extract returned items
  Future<void> _processDocumentWithOcr() async {
    // First check if there are already returnedItems in ocrResults
    if (widget.ocrResults.containsKey('returnedItems') &&
        (widget.ocrResults['returnedItems'] as List).isNotEmpty) {
      _processOcrResults();
      return;
    }

    // If no pre-processed results, run OCR on the document
    setState(() {
      _isProcessingDocument = true;
    });

    try {
      // Process the first image in documentPaths with the Return Item OCR API
      if (_documentPaths.isNotEmpty) {
        final imageFile = File(_documentPaths.first);
        final ReturnItemOcrResponse ocrResponse =
            await _ocrService.getReturnItemsFromImage(imageFile);

        // If OCR successful, update the returnedItems list
        if (ocrResponse.data.itemsData.isNotEmpty) {
          setState(() {
            _returnedItems.clear();
            // Convert ReturnItem objects to the map format expected by the UI
            for (var item in ocrResponse.data.itemsData) {
              _returnedItems.add(item.toDisplayFormat());
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing document with OCR: $e');
      // If OCR fails, still try to use any returnedItems from ocrResults
      _processOcrResults();
    } finally {
      setState(() {
        _isProcessingDocument = false;
      });
    }
  }

  void _processOcrResults() {
    // Extract returned items from OCR results
    if (widget.ocrResults.containsKey('returnedItems')) {
      setState(() {
        _returnedItems.addAll(
          List<Map<String, dynamic>>.from(widget.ocrResults['returnedItems']),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _submitReturnData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      // Create list of File objects from document paths
      final List<File> documentFiles =
          _documentPaths.map((path) => File(path)).toList();

      // Use the ReturnDeliveryService to submit the return data
      final returnDeliveryService = ReturnDeliveryService();
      final response = await returnDeliveryService.submitReturnDelivery(
        orderNo: widget.package.id,
        reason: widget.returnReason,
        returnItems: _returnedItems,
        images: documentFiles,
        notes: _notesController.text,
      );

      // Show success dialog with message from response
      final message = response['message'] ?? 'Return berhasil disimpan';
      if (mounted) {
        _showSuccessDialog(message);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data return: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog([String? message]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF306424).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF306424),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Return Berhasil Disimpan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      'Data return untuk paket ${widget.package.id} telah berhasil disimpan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close dialog
                      Navigator.pop(context);

                      // Set result to true and pop to return screen
                      Navigator.of(context).pop(true);

                      // Pop until we get back to home screen
                      // This is more robust than using named routes
                      Navigator.of(context).popUntil((route) {
                        return route.settings.name == '/' || route.isFirst;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF306424),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to navigate between document pages
  void _navigateToDocumentPage(int index) {
    if (index >= 0 && index < _documentPaths.length) {
      setState(() {
        _currentDocumentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Konfirmasi Return',
          style: TextStyle(
            color: Color(0xFF306424),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF306424)),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPackageInfoSection(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        children: [
                          _buildImagePreviewSection(),
                          const SizedBox(height: 20),
                          _buildReturnDetailsSection(),
                          const SizedBox(height: 20),
                          _buildReturnedItemsSection(),
                          const SizedBox(height: 20),
                          _buildNotesSection(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    _buildBottomActionBar(),
                  ],
                ),
              ),
            ),
          ),

          // Full screen document image viewer
          if (_showFullDocumentImage) _buildFullScreenDocumentViewer(),

          // Loading overlay during OCR processing
          if (_isProcessingDocument)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF306424),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memproses dokumen...\nMengidentifikasi item return',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

  Widget _buildPackageInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.package.id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF306424),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Return',
                  style: TextStyle(
                    color: Color(0xFFC0392B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.package.recipient,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.package.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Preview Dokumen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF306424),
              ),
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
                  color: const Color(0xFF306424).withOpacity(0.1),
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
        const SizedBox(height: 4),
        Text(
          'Hasil scan dokumen delivery (${_documentPaths.length} halaman)',
          style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6)),
        ),
        const SizedBox(height: 16),

        // Document preview with pagination
        Column(
          children: [
            // Image container with portrait ratio
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFullDocumentImage = true;
                });
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 4, // Portrait ratio (3:4)
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_documentPaths[_currentDocumentIndex]),
                            fit: BoxFit.cover),

                        // Gradient overlay at bottom
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
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Text(
                              'Dokumen Delivery Order - Hal. ${_currentDocumentIndex + 1}/${_documentPaths.length}',
                              style: const TextStyle(
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
            ),

            // Dokumen pagination controls (hanya tampilkan jika lebih dari 1 halaman)
            if (_documentPaths.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentDocumentIndex > 0
                          ? () =>
                              _navigateToDocumentPage(_currentDocumentIndex - 1)
                          : null,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: _currentDocumentIndex > 0
                            ? const Color(0xFF306424)
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                    Text(
                      'Halaman ${_currentDocumentIndex + 1} dari ${_documentPaths.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      onPressed: _currentDocumentIndex <
                              _documentPaths.length - 1
                          ? () =>
                              _navigateToDocumentPage(_currentDocumentIndex + 1)
                          : null,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: _currentDocumentIndex < _documentPaths.length - 1
                            ? const Color(0xFF306424)
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReturnDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Return',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF306424),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Alasan Return:', widget.returnReason),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Tanggal Return:',
            DateTime.now().toString().substring(0, 10),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Total Item Return:',
            '${_returnedItems.length} item',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item yang Dikembalikan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF306424),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hasil deteksi dari dokumen',
          style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _returnedItems.isEmpty
              ? _buildEmptyReturnedItemsMessage()
              : _buildReturnedItemsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyReturnedItemsMessage() {
    // Check if it was a no-items-found result from OCR or another issue
    bool noItemsDetected = widget.ocrResults.containsKey('noItemsFound') &&
        widget.ocrResults['noItemsFound'] == true;
    bool ocrError = widget.ocrResults.containsKey('ocrError') &&
        widget.ocrResults['ocrError'] != null;

    String message = noItemsDetected
        ? 'Tidak ada item return yang terdeteksi pada dokumen'
        : ocrError
            ? 'Gagal memproses dokumen. Silakan coba lagi'
            : 'Tidak ada item yang terdeteksi';

    IconData iconData = noItemsDetected
        ? Icons.search_off
        : ocrError
            ? Icons.error_outline
            : Icons.inventory_2_outlined;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Pop back to the camera screen
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Ambil Foto Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnedItemsList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _returnedItems.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.withOpacity(0.2),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = _returnedItems[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            item['name'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Alasan: ${item['reason']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Text(
            'Qty: ${item['qty']}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        );
      },
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catatan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF306424),
              ),
            ),
            Text(
              'Dapat diedit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _notesController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan di sini',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    // Check if confirmation button should be disabled (when no items detected)
    bool isConfirmButtonDisabled = _returnedItems.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Kembali Button
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF306424)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      color: Color(0xFF306424),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Konfirmasi Button - Now disabled when no items are detected
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || isConfirmButtonDisabled)
                      ? null
                      : _submitReturnData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF306424),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF306424).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isConfirmButtonDisabled
                              ? 'Tidak ada item'
                              : 'Konfirmasi',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method for full screen document viewer dengan dukungan multi halaman
  Widget _buildFullScreenDocumentViewer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFullDocumentImage = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.9),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Document image
            Center(
              child: InteractiveViewer(
                child: Image.file(File(_documentPaths[_currentDocumentIndex])),
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

            // Pagination controls - positioned at the bottom
            if (_documentPaths.length > 1)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    if (_currentDocumentIndex > 0)
                      IconButton(
                        onPressed: () =>
                            _navigateToDocumentPage(_currentDocumentIndex - 1),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                    // Document page indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Halaman ${_currentDocumentIndex + 1} / ${_documentPaths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Next button
                    if (_currentDocumentIndex < _documentPaths.length - 1)
                      IconButton(
                        onPressed: () =>
                            _navigateToDocumentPage(_currentDocumentIndex + 1),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
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
}
