import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/package.dart';
import '../services/ocr_service.dart';
import '../models/ocr_response_model.dart';
import '../services/return_delivery_service.dart';
import '../services/package_detail_service.dart';
import '../models/package_detail_model.dart';
import 'home_screen.dart';

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
  bool _showManualSelection = false; // Flag untuk menampilkan seleksi manual
  final List<Map<String, dynamic>> _returnedItems = [];
  final List<Map<String, dynamic>> _availableItems =
      []; // Daftar item yang tersedia pada paket
  final List<Map<String, dynamic>> _selectedItems =
      []; // Item yang dipilih secara manual
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OcrService _ocrService = OcrService();
  final PackageDetailService _packageDetailService = PackageDetailService();
  // Currency formatter
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Helper methods to handle null/empty data and formatting
  String _formatPrice(dynamic price) {
    if (price == null) return '-';

    try {
      if (price is String) {
        if (price.isEmpty) return '-';
        final numPrice = double.tryParse(price);
        if (numPrice == null) return '-';
        return _currencyFormatter.format(numPrice);
      } else if (price is num) {
        if (price == 0) return '-';
        return _currencyFormatter.format(price);
      }
      return '-';
    } catch (e) {
      debugPrint('Error formatting price: $e');
      return '-';
    }
  }

  String _safeString(dynamic value, [String defaultValue = '-']) {
    if (value == null) return defaultValue;
    if (value is String && value.isEmpty) return defaultValue;
    return value.toString();
  }

  int _safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  String _formatQuantity(dynamic qty) {
    final quantity = _safeDouble(qty, 0.0);
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString(); // Show as int if no decimal part
    }
    return quantity.toString(); // Show with decimal if needed
  }

  // Debug method to check field mapping - SIMPLIFIED
  void _debugFieldMapping() {
    print('Total returned items: ${_returnedItems.length}');
  }

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
        final List<Map<String, dynamic>> ocrItems =
            List<Map<String, dynamic>>.from(widget.ocrResults['returnedItems']);

        // Process each OCR item and ensure field consistency
        for (final item in ocrItems) {
          // Ensure quantity and price fields are properly mapped for all OCR sources
          final double quantity =
              _safeDouble(item['quantity'] ?? item['qty'], 1.0);
          final double returnQuantity = _safeDouble(
              item['returnQuantity'] ?? item['returnQty'], quantity);
          final double unitPrice =
              _safeDouble(item['unitPrice'] ?? item['price'], 0.0);

          // Determine confidence level from various sources
          double confidence = _safeDouble(item['confidence'], 0.0);

          // For Paddle OCR results, items with return quantity > 0 have high confidence
          if (item['source'] == 'paddle_ocr' && returnQuantity > 0) {
            confidence = confidence > 0.8 ? confidence : 0.8;
          }

          // Check if the item should be auto-checked based on:
          // 1. Explicit autoChecked flag
          // 2. High confidence from Paddle OCR (> 0.7)
          // 3. Source is paddle_ocr with return quantity specified
          final bool shouldAutoCheck = item['autoChecked'] == true ||
              confidence >= 0.7 ||
              (item['source'] == 'paddle_ocr' && returnQuantity > 0);

          // Create consistent item with all necessary fields
          final processedItem = {
            ...item,
            // Ensure both field names are available for UI compatibility
            'qty': quantity,
            'quantity': quantity,
            'returnQty': returnQuantity,
            'returnQuantity': returnQuantity,
            'price': unitPrice,
            'unitPrice': unitPrice,
            'reason': item['reason'] ?? 'Item Kurang Segar',
            'unitMetrics': item['unitMetrics'] ?? 'kg',
            'autoChecked': shouldAutoCheck, // Add auto-check flag
            'source': item['source'] ?? 'ocr', // Track data source
            'confidence': confidence, // Store normalized confidence
          };
          _returnedItems.add(processedItem);
        }

        // Call debug method to check field mapping
        _debugFieldMapping();
      });
    }

    // Check if OCR didn't find any items, and if so, load available items for manual selection
    if (_returnedItems.isEmpty) {
      _loadAvailableItems();
    }
  }

  // Load available package items for manual selection
  Future<void> _loadAvailableItems() async {
    setState(() {
      _isProcessingDocument = true;
    });
    try {
      // Fetch package details from API using the package ID
      final PackageDetailData packageData =
          await _packageDetailService.getPackageDetail(widget.package.id);
      // Convert package items to the format needed for the UI with safe type conversion
      final List<Map<String, dynamic>> packageItems =
          packageData.items.map((item) {
        // Safe conversion using helper methods
        final int safePrice = _safeInt(
            item.unitPrice, 15000); // Use unitPrice directly with fallback
        final double safeQuantity = _safeDouble(item.quantity, 1.0);
        final double safeWeight = item.weight > 0 ? item.weight : 0.5;
        final String safeName = _safeString(item.name, 'Unknown Item');
        final String safeNotes = _safeString(item.notes, '');

        return {
          'id': safeName.hashCode.toString(),
          'name': safeName,
          'qty': safeQuantity,
          'price': safePrice,
          'weight': safeWeight,
          'unitMetrics': safeWeight > 0 ? 'kg' : 'pcs',
          'sku': safeNotes.isNotEmpty
              ? safeNotes
              : 'VEG-${safeName.length >= 3 ? safeName.substring(0, 3).toUpperCase() : safeName.toUpperCase()}',
        };
      }).toList();

      if (packageItems.isEmpty) {
        throw Exception('No items found in package');
      }
      setState(() {
        _availableItems.clear();
        _availableItems.addAll(packageItems);

        // Auto-check items that were detected by OCR
        _autoCheckDetectedItems();

        _showManualSelection = true;
      });
    } catch (e) {
      debugPrint('Error loading available items: $e');

      // Show error without fallback data - let user retry API call or take photo again
      setState(() {
        _isProcessingDocument = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data item: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () {
                _loadAvailableItems(); // Retry API call
              },
            ),
          ),
        );
      }
      return; // Don't show manual selection if API fails
    } finally {
      setState(() {
        _isProcessingDocument = false;
      });
    }
  }
  // Method removed as it's not being used

  // Update the return quantity for a selected item
  void _updateReturnQuantity(String id, double qty) {
    setState(() {
      // Find the item in both lists
      final int selectedIndex =
          _selectedItems.indexWhere((item) => item['id'] == id);
      if (selectedIndex >= 0) {
        // Ensure quantity is within valid range (0.1 to max available)
        final double maxQty =
            _safeDouble(_selectedItems[selectedIndex]['qty'], 1.0);
        final double newQty = qty.clamp(0.1, maxQty);

        _selectedItems[selectedIndex]['returnQty'] = newQty;
      }

      // Also update in returnedItems list
      final int returnedIndex =
          _returnedItems.indexWhere((item) => item['id'] == id);
      if (returnedIndex >= 0) {
        final double maxQty =
            _safeDouble(_returnedItems[returnedIndex]['qty'], 1.0);
        final double newQty = qty.clamp(0.1, maxQty);

        _returnedItems[returnedIndex]['returnQty'] = newQty;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _submitReturnData() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final List<File> documentFiles =
          _documentPaths.map((path) => File(path)).toList();
      final returnDeliveryService = ReturnDeliveryService();
      // Build the correct returnItems body for API
      final List<Map<String, dynamic>> returnItems = _returnedItems
          .map((item) => {
                'id': _safeString(item['id'], ''),
                'name': _safeString(item['name'], 'Unknown Item'),
                'qty': _safeDouble(item['qty'], 1.0),
                'returnQty': _safeDouble(
                    item['returnQty'], _safeDouble(item['qty'], 1.0)),
                'price': _safeInt(item['price'], 0),
                'reason': _safeString(item['reason'], 'Item Kurang Segar'),
                'unitMetrics': _safeString(item['unitMetrics'], 'kg'),
              })
          .toList();
      final response = await returnDeliveryService.submitReturnDelivery(
        orderNo: widget.package.id,
        reason: widget.returnReason,
        returnItems: returnItems,
        images: documentFiles,
        notes: _notesController.text,
      );
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
                    color: const Color(0xFF306424).withValues(alpha: 0.1),
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
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      // Navigate to HomeScreen and remove all previous routes
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
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

  // Auto-check items that were detected by OCR to prevent duplicates
  void _autoCheckDetectedItems() {
    // Only proceed if we have both OCR results and available items
    if (_returnedItems.isEmpty || _availableItems.isEmpty) return;

    // For each OCR detected item, try to find a match in available items
    for (final ocrItem in _returnedItems) {
      final String ocrItemName = _safeString(ocrItem['name'], '').toLowerCase();
      final bool wasAutoDetected = ocrItem['autoChecked'] == true ||
          ocrItem['source'] == 'paddle_ocr' ||
          (_safeDouble(ocrItem['confidence'], 0.0) >= 0.7);

      // Skip items that weren't auto-detected
      if (!wasAutoDetected) continue;

      // Find best matching item using improved matching algorithm
      Map<String, dynamic>? bestMatch;
      double bestMatchScore = 0.0;

      // Try to find a matching item in the available items by name
      for (final availableItem in _availableItems) {
        final String availableItemName =
            _safeString(availableItem['name'], '').toLowerCase();

        // Improved matching with weighted scoring
        double matchScore = 0.0;

        // Exact match gets highest score
        if (availableItemName == ocrItemName) {
          matchScore = 1.0;
        }
        // Check if one contains the other completely
        else if (availableItemName.contains(ocrItemName)) {
          // Longer the overlap, better the match
          matchScore = 0.8 * (ocrItemName.length / availableItemName.length);
        } else if (ocrItemName.contains(availableItemName)) {
          matchScore = 0.8 * (availableItemName.length / ocrItemName.length);
        }
        // Check for partial word matches
        else {
          // Split into words and check for common words
          List<String> ocrWords = ocrItemName.split(RegExp(r'\s+'));
          List<String> availableWords = availableItemName.split(RegExp(r'\s+'));

          int matchedWords = 0;
          for (String ocrWord in ocrWords) {
            if (ocrWord.length > 2) {
              // Only consider words longer than 2 chars
              for (String availableWord in availableWords) {
                if (availableWord.length > 2 &&
                    (availableWord.contains(ocrWord) ||
                        ocrWord.contains(availableWord))) {
                  matchedWords++;
                  break;
                }
              }
            }
          }

          if (matchedWords > 0) {
            // Calculate score based on percentage of words matched
            matchScore = 0.5 * (matchedWords / ocrWords.length);
          }
        }

        // If this match is better than previous best, update best match
        if (matchScore > bestMatchScore) {
          bestMatchScore = matchScore;
          bestMatch = availableItem;
        }
      }

      // If we have a good match (score threshold), use it
      if (bestMatchScore > 0.3 && bestMatch != null) {
        // Create a copy with OCR-detected return quantity and reason
        final Map<String, dynamic> itemWithOcrData = {
          ...bestMatch,
          'returnQty': ocrItem['returnQty'],
          'reason': ocrItem['reason'] ?? 'Item Kurang Segar',
          'autoChecked': true, // Mark as auto-checked
          'source':
              ocrItem['source'] ?? 'paddle_ocr', // Preserve source information
          'matchConfidence':
              bestMatchScore, // Store match confidence for debugging
        };

        // Add to selected items if not already present in either list
        final bool alreadyExistsById =
            _selectedItems.any((item) => item['id'] == bestMatch!['id']) ||
                _returnedItems.any((item) => item['id'] == bestMatch!['id']);
        final bool alreadyExistsByName = _selectedItems
                .any((item) => item['name'] == bestMatch!['name']) ||
            _returnedItems.any((item) => item['name'] == bestMatch!['name']);
        if (!alreadyExistsById && !alreadyExistsByName) {
          _selectedItems.add(itemWithOcrData);
        }
      }
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
              color: Colors.black.withValues(alpha: 0.5),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                _safeString(widget.package.id, 'No Package ID'),
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
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.15),
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
                  _safeString(widget.package.recipient, 'No Recipient'),
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
                  _safeString(widget.package.address, 'No Address'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.7),
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
        const SizedBox(height: 4),
        Text(
          'Hasil scan dokumen delivery (${_documentPaths.length} halaman)',
          style: TextStyle(
              fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                                  Colors.black.withValues(alpha: 0.7),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              color: Colors.black.withValues(alpha: 0.6),
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
          _showManualSelection
              ? 'Pilihan manual oleh driver'
              : 'Hasil deteksi dari dokumen',
          style: TextStyle(
              fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: _showManualSelection
              ? _buildManualSelectionInterface()
              : _returnedItems.isEmpty
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
            // Camera button
            SizedBox(
              width: 200, // Set a fixed width for consistent button size
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pop back to the camera screen
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[800],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Ambil Foto Ulang'),
              ),
            ),
            const SizedBox(
                height:
                    24), // Increased spacing for visual separation            // Manual selection button - Made smaller and more modern
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _loadAvailableItems();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF306424),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8), // Reduced from 10 to 8
                    elevation: 1,
                    shadowColor: const Color(0xFF306424).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Reduced from 12 to 10
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline,
                      size: 14), // Reduced from 16 to 14
                  label: const Text(
                    'Tambah Item Manual',
                    style: TextStyle(
                      fontSize: 12, // Reduced from 13 to 12
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
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

  // New method to build the manual selection interface
  Widget _buildManualSelectionInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF306424).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF306424),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pilih Item Return Manual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF306424),
                      ),
                    ),
                  ),
                  // Add back button if there are already returned items
                  if (_returnedItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showManualSelection = false;
                          _selectedItems.clear();
                        });
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 16,
                        color: Color(0xFF306424),
                      ),
                      label: const Text(
                        'Kembali',
                        style: TextStyle(
                          color: Color(0xFF306424),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Centang item dan atur jumlah return',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Item terpilih: ${_selectedItems.length} dari ${_availableItems.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selectedItems.isNotEmpty
                      ? const Color(0xFF306424)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _availableItems.length, // Show ALL items
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final item = _availableItems[index];
            final double maxQty = _safeDouble(item['qty'], 1.0);

            // Check if this item is already in _returnedItems or _selectedItems
            final int returnedIndex =
                _returnedItems.indexWhere((i) => i['id'] == item['id']);
            final int selectedIndex =
                _selectedItems.indexWhere((i) => i['id'] == item['id']);
            final bool isInReturned = returnedIndex >= 0;
            final bool isInSelected = selectedIndex >= 0;
            final bool isSelected = isInReturned ||
                isInSelected; // FIXED: Use simple and consistent logic - an item is auto-detected ONLY if it's in _returnedItems and meets OCR criteria
            final bool isAutoDetected = isInReturned &&
                returnedIndex >= 0 &&
                (_returnedItems[returnedIndex]['autoChecked'] == true ||
                    _returnedItems[returnedIndex]['source'] == 'paddle_ocr' ||
                    _returnedItems[returnedIndex]['source'] == 'ocr' ||
                    (_returnedItems[returnedIndex]['isOcrDetected'] == true) ||
                    (_safeDouble(
                            _returnedItems[returnedIndex]['confidence'], 0.0) >=
                        0.7));

            final qtyController = TextEditingController(
                text: _formatQuantity(isInReturned
                    ? _safeDouble(
                        _returnedItems[returnedIndex]['returnQty'], 1.0)
                    : isInSelected
                        ? _safeDouble(
                            _selectedItems[selectedIndex]['returnQty'], 1.0)
                        : 1.0));

            return Container(
                decoration: BoxDecoration(
                  // Add light highlighting for auto-detected items
                  color: isAutoDetected
                      ? Colors.green.withValues(alpha: 0.05)
                      : Colors.white,
                  border: isAutoDetected
                      ? Border.all(color: Colors.green.withValues(alpha: 0.1))
                      : null,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Checkbox(
                    value: isSelected,
                    activeColor: isAutoDetected
                        ? Colors.green
                        : const Color(
                            0xFF306424), // Disable checkbox for auto-detected items to prevent unchecking
                    onChanged: isAutoDetected
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true && !isSelected) {
                                // Only add if not already present in either list (check both ID and name)
                                final bool alreadyExistsById =
                                    _selectedItems.any((existingItem) =>
                                            existingItem['id'] == item['id']) ||
                                        _returnedItems.any((existingItem) =>
                                            existingItem['id'] == item['id']);
                                final bool alreadyExistsByName = _selectedItems
                                        .any((existingItem) =>
                                            existingItem['name'] ==
                                            item['name']) ||
                                    _returnedItems.any((existingItem) =>
                                        existingItem['name'] == item['name']);

                                if (!alreadyExistsById &&
                                    !alreadyExistsByName) {
                                  final Map<String, dynamic> itemWithReason = {
                                    ...item,
                                    'reason':
                                        'Item Kurang Segar', // Updated default reason
                                    'returnQty': 1.0,
                                    'autoChecked': false, // Manually checked
                                  };
                                  _selectedItems.add(itemWithReason);
                                  debugPrint(
                                      'Added manual item: ${item['name']}');
                                } else {
                                  debugPrint(
                                      'Item ${item['name']} already exists, skipping');
                                }
                              } else if (checked == false && isSelected) {
                                // Allow unchecking for all manually selected items
                                if (isInSelected) {
                                  _selectedItems.removeAt(selectedIndex);
                                  debugPrint(
                                      'Removed manual item: ${item['name']}');
                                } else if (isInReturned && !isAutoDetected) {
                                  // Allow unchecking manually added items that are in _returnedItems
                                  _returnedItems.removeAt(returnedIndex);
                                  debugPrint(
                                      'Removed returned manual item: ${item['name']}');
                                }
                              }
                            });
                          },
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safeString(item['name'], 'Unknown Item'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isAutoDetected
                              ? Colors.green[700]
                              : isSelected
                                  ? const Color(0xFF306424)
                                  : Colors.black87,
                        ),
                      ),
                      if (isAutoDetected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text(
                                  'Terdeteksi OCR',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: isSelected
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Flexible(
                                  child: Text('Jumlah return:',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700])),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 48,
                                  height: 32,
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 0, horizontal: 8),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final double? valDouble =
                                          double.tryParse(val);
                                      if (valDouble != null &&
                                          valDouble > 0 &&
                                          valDouble <= maxQty) {
                                        _updateReturnQuantity(
                                            item['id'] as String, valDouble);
                                      } else if (valDouble != null &&
                                          valDouble > maxQty) {
                                        _updateReturnQuantity(
                                            item['id'] as String, maxQty);
                                        qtyController.text =
                                            _formatQuantity(maxQty);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('Max: ${_formatQuantity(maxQty)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600])),
                                ),
                              ],
                            ),
                          ],
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          '${_formatQuantity(_safeDouble(item['weight'], 0.0))} ${item['unitMetrics'] ?? 'kg'}',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: isSelected
                                  ? const Color(0xFF306424)
                                  : Colors.black87)),
                      const SizedBox(height: 4),
                      Text(_formatPrice(item['price']),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ));
          },
        ),
        if (_selectedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Pilih minimal 1 item untuk direturn',
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600]),
              ),
            ),
          ),
        // Tombol simpan pilihan manual
        if (_selectedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16), // Reduced vertical from 20 to 16
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Improved merge logic to prevent duplicates
                    for (final selectedItem in _selectedItems) {
                      final String itemId = selectedItem['id'] as String;
                      final String itemName = selectedItem['name'] as String;

                      // Check if item already exists in returned items by both ID and name
                      final int existingIndex = _returnedItems.indexWhere(
                          (item) =>
                              item['id'] == itemId || item['name'] == itemName);

                      if (existingIndex >= 0) {
                        // Update existing item with new data from selected items
                        _returnedItems[existingIndex] = {
                          ..._returnedItems[existingIndex],
                          ...selectedItem,
                          'source':
                              'manual_selection', // Mark as manually selected
                        };
                        debugPrint('Updated existing item: $itemName');
                      } else {
                        // Add new item to returned items only if it doesn't exist
                        final newItem = {
                          ...selectedItem,
                          'source': 'manual_selection',
                        };
                        _returnedItems.add(newItem);
                        debugPrint('Added new item: $itemName');
                      }
                    }

                    // Clear selected items and exit manual selection mode
                    _selectedItems.clear();
                    _showManualSelection = false;

                    debugPrint(
                        'Total returned items after merge: ${_returnedItems.length}');
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF306424),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12), // Reduced from 16 to 12
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Reduced from 12 to 10
                  ),
                  elevation: 1, // Reduced from 2 to 1
                  shadowColor: const Color(0xFF306424)
                      .withValues(alpha: 0.2), // Reduced opacity
                ),
                child: const Text(
                  'Simpan Pilihan Manual',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600), // Reduced from 16 to 14
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Catatan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF306424),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Opsional)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
    bool isConfirmButtonDisabled = _returnedItems.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF306424),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF306424),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Submit Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReturnData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmButtonDisabled
                        ? Colors.grey[400]
                        : const Color(0xFF306424),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: isConfirmButtonDisabled ? 0 : 2,
                    shadowColor: const Color(0xFF306424).withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.5))
                      : const Text(
                          'Simpan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenDocumentViewer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFullDocumentImage = false;
        });
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Stack(
          children: [
            // Image container with pinch-to-zoom
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(_documentPaths[_currentDocumentIndex]),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    _showFullDocumentImage = false;
                  });
                },
              ),
            ),

            // Document pagination
            if (_documentPaths.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_documentPaths.length, (index) {
                    final bool isActive = index == _currentDocumentIndex;
                    return GestureDetector(
                      onTap: () => _navigateToDocumentPage(index),
                      child: Container(
                        width: isActive ? 12 : 8,
                        height: isActive ? 12 : 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Left-right navigation buttons for documents
            if (_documentPaths.length > 1) ...[
              // Left button
              if (_currentDocumentIndex > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 40),
                      onPressed: () =>
                          _navigateToDocumentPage(_currentDocumentIndex - 1),
                    ),
                  ),
                ),

              // Right button
              if (_currentDocumentIndex < _documentPaths.length - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 40),
                      onPressed: () =>
                          _navigateToDocumentPage(_currentDocumentIndex + 1),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Method to build the list of returned items detected by OCR
  Widget _buildReturnedItemsList() {
    return Column(
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _returnedItems.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          itemBuilder: (context, index) {
            final item = _returnedItems[
                index]; // Check if this item was auto-detected by OCR
            final bool isAutoDetected = item['autoChecked'] == true ||
                item['source'] == 'paddle_ocr' ||
                (_safeDouble(item['confidence'], 0.0) >= 0.7);

            final double price = _safeDouble(item['price'], 0.0);

            return Container(
              decoration: BoxDecoration(
                // Add light green background for auto-detected items
                color: isAutoDetected
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.white,
                border: isAutoDetected
                    ? Border.all(color: Colors.green.withValues(alpha: 0.1))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First row: Item name and OCR badge only
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _safeString(item['name'], 'Unknown Item'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Badge "Terdeteksi OCR" di sisi kanan
                        if (isAutoDetected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text(
                                  'Terdeteksi OCR',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row: Weight data, return quantity, and price
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Return quantity display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF306424)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF306424)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.assignment_return,
                                      size: 14,
                                      color: Color(0xFF306424),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Qty Return: ${_formatQuantity(_safeDouble(item['returnQty'], 0.0))}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF306424),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatQuantity(_safeDouble(item['weight'], 0.0))} ${item['unitMetrics'] ?? 'kg'}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatPrice(price),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16), // Reduced from 20 to 16
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadAvailableItems();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF306424),
                side: const BorderSide(
                  color: Color(0xFF306424),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 12), // Reduced from 16 to 12
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // Reduced from 12 to 10
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_outline,
                  size: 18), // Reduced from 20 to 18
              label: const Text(
                'Tambah Item Manual',
                style: TextStyle(
                  fontSize: 14, // Reduced from 16 to 14
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
