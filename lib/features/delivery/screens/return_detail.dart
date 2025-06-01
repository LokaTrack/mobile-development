import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/package.dart';
import '../models/return_detail_model.dart';
import '../services/return_detail_service.dart';
import '../../auth/services/auth_service.dart';
import 'package_detail.dart';

class ReturnDetailScreen extends StatefulWidget {
  final Package package;
  final String? documentImagePath; // Optional parameter for document image

  const ReturnDetailScreen({
    Key? key,
    required this.package,
    this.documentImagePath,
  }) : super(key: key);

  @override
  State<ReturnDetailScreen> createState() => _ReturnDetailScreenState();
}

class _ReturnDetailScreenState extends State<ReturnDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showFullDocumentImage = false;
  // API related state
  final ReturnDetailService _returnDetailService = ReturnDetailService();
  final AuthService _authService = AuthService();
  ReturnDetailData? _returnDetailData;
  bool _isLoading = true;
  String? _errorMessage;
  String _driverName = 'Driver';

  // Define colors
  final Color primaryColor = const Color(0xFF306424); // Main green color
  final Color returnStatusColor =
      const Color(0xFFC0392B); // Red for return status elements
  final moneyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Helper functions for safe data formatting with default values
  String _safeString(String? value, [String defaultValue = "-"]) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  String _safeWeightWithUnit(double? weight, String? unitMetrics) {
    if (weight == null || weight <= 0) return "-";
    final unit = _safeString(unitMetrics, "kg");
    return "$weight $unit";
  }

  String _safeQuantity(dynamic quantity) {
    if (quantity == null) return "-";
    if (quantity is int && quantity <= 0) return "-";
    if (quantity is double && quantity <= 0) return "-";
    if (quantity is int) return quantity.toString();
    if (quantity is double) {
      // Show decimal only if needed
      if (quantity == quantity.toInt()) {
        return quantity.toInt().toString();
      } else {
        return quantity.toString();
      }
    }
    return quantity.toString();
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReturnDetail();

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadReturnDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load return detail data
      final returnDetail =
          await _returnDetailService.getReturnDetail(widget.package.id);

      // Load driver name from auth service
      final userData = await _authService.getUserData();
      final driverName = userData?['username'] ?? userData?['name'] ?? 'Driver';

      setState(() {
        _returnDetailData = returnDetail.data;
        _driverName = driverName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading return detail: $e');
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5), // Consistent with other screens
      body: Stack(
        children: [
          // Background decorations
          _buildBackgroundDecorations(size),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingState()
                          : _errorMessage != null
                              ? _buildErrorState()
                              : _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Full screen document image viewer
          if (_showFullDocumentImage) _buildFullScreenDocumentViewer(),
        ],
      ),
      bottomNavigationBar:
          !_isLoading && _errorMessage == null ? _buildBottomBar() : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat detail return...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat detail return',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReturnDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryColor,
                size: 18,
              ),
            ),
          ),

          // Title with red icon for return status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_return_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Detail Return',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          // Empty container to balance the row (replacing the more button)
          const SizedBox(width: 40),
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
              color: primaryColor.withOpacity(0.08),
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
              color: primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Small accent circles - using return color for some variety
        Positioned(
          left: size.width * 0.2,
          top: size.height * 0.15,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: returnStatusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: size.width * 0.3,
          bottom: size.height * 0.25,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: returnStatusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_returnDetailData == null) return Container();

    final formattedReturnDate =
        DateFormat('dd MMMM yyyy, HH:mm').format(_returnDetailData!.returnDate);
    final formattedOrderDate =
        DateFormat('dd MMMM yyyy').format(widget.package.scheduledDelivery);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Return Status Banner
          _buildStatusBanner(),

          const SizedBox(height: 20),

          // Quick Info Grid
          _buildQuickInfoGrid(formattedReturnDate),

          const SizedBox(height: 20),

          // Document Image Section
          _buildDocumentImageSection(),

          const SizedBox(height: 20),

          // Return Information Section
          _buildSectionWithCustomTitle(
            title: 'Informasi Return',
            icon: Icons.assignment_return,
            child: _buildReturnInfoCard(formattedReturnDate),
          ),

          const SizedBox(height: 20),

          // Customer Information Section
          _buildSectionWithCustomTitle(
            title: 'Informasi Penerima',
            icon: Icons.person,
            child: _buildCustomerInfoCard(),
          ),

          const SizedBox(height: 20),

          // Order Information Section
          _buildSectionWithCustomTitle(
            title: 'Informasi Pesanan',
            icon: Icons.shopping_bag,
            child: _buildOrderInfoCard(formattedOrderDate),
          ),

          const SizedBox(height: 20),

          // Items Information Section with enhanced details
          _buildSectionWithCustomTitle(
            title: 'Detail Item',
            icon: Icons.inventory_2,
            child: _buildItemsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithCustomTitle({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    final color = iconColor ?? primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildStatusBanner() {
    if (_returnDetailData == null) return Container();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
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
              // ID Paket section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Paket',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          color: primaryColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _returnDetailData!.orderNo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status badge - using red for return status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: returnStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: returnStatusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Return',
                      style: TextStyle(
                        color: returnStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Reason section with red info icon - made more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: returnStatusColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: returnStatusColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: returnStatusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alasan: ${_returnDetailData!.reason}',
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }

  Widget _buildQuickInfoGrid(String returnDate) {
    if (_returnDetailData == null) return Container();

    // Use API data for item count
    final itemCount = _returnDetailData!.totalItems;
    final formattedDate =
        DateFormat('dd MMM yyyy').format(_returnDetailData!.returnDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // First row with recipient and return date
          Row(
            children: [
              // Recipient info
              Expanded(
                child: _buildCardInfoItem(
                  icon: Icons.person_outlined,
                  title: 'Penerima',
                  value: widget.package.recipient,
                  hasBorder: true,
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),

              // Return date
              Expanded(
                child: _buildCardInfoItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Tanggal Return',
                  value: formattedDate,
                  iconColor: returnStatusColor,
                ),
              ),
            ],
          ),

          // Divider between rows
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.grey.shade200,
          ),

          // Second row with total and item count
          Row(
            children: [
              // Total payment
              Expanded(
                child: _buildCardInfoItem(
                  icon: Icons.payment_outlined,
                  title: 'Total',
                  value: moneyFormat.format(_returnDetailData!.totalPrice),
                  hasBorder: true,
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),

              // Item count
              Expanded(
                child: _buildCardInfoItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Item',
                  value: '$itemCount Item',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _safeWeightWithUnit(_returnDetailData!.totalWeight, "kg"),
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    Color? valueColor,
    Widget? trailing,
    bool hasBorder = false,
    BorderSide? borderSide,
  }) {
    final color = iconColor ?? primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border:
            hasBorder && borderSide != null ? Border(right: borderSide) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: valueColor ?? Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 4),
                      trailing,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentImageSection() {
    if (_returnDetailData == null) return Container();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dokumen Delivery Order',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Bukti dokumen return',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // View document button
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
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fullscreen,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lihat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Document image
          GestureDetector(
            onTap: () {
              setState(() {
                _showFullDocumentImage = true;
              });
            },
            child: Stack(
              children: [
                // Use URL from API if available, otherwise fallback to example image
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: _returnDetailData!.deliveryOrderImages.isNotEmpty
                        ? Image.network(
                            _returnDetailData!.deliveryOrderImages.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/delivery_order_example.jpg',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/delivery_order_example.jpg',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                // Gradient overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ), // Dynamic badge showing return date
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_return_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Return ${DateFormat('dd/MM/yyyy').format(_returnDetailData!.returnDate)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenDocumentViewer() {
    if (_returnDetailData == null) return Container();

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
                child: _returnDetailData!.deliveryOrderImages.isNotEmpty
                    ? Image.network(
                        _returnDetailData!.deliveryOrderImages.first,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                              'assets/images/delivery_order_example.jpg');
                        },
                      )
                    : Image.asset('assets/images/delivery_order_example.jpg'),
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

  Widget _buildReturnInfoCard(String returnDate) {
    if (_returnDetailData == null) return Container();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHorizontalInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Tanggal Return',
            value: returnDate,
            iconColor: primaryColor, // Red icon for return date
          ),
          const SizedBox(height: 12),
          _buildHorizontalInfoRow(
            icon: Icons.person_outline,
            title: 'Diproses oleh',
            value: _safeString(_driverName),
          ),
          const SizedBox(height: 12),
          _buildHorizontalInfoRow(
            icon: Icons.note_outlined,
            title: 'Catatan',
            value: _safeString(widget.package.notes),
            isMultiLine: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    // Mock phone number (in real app, this would come from the Package model)
    const phoneNumber = "0812-3456-7890";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHorizontalInfoRow(
            icon: Icons.person_outline,
            title: 'Nama Penerima',
            value: widget.package.recipient.isEmpty
                ? "-"
                : widget.package.recipient,
          ),
          const SizedBox(height: 12),
          _buildHorizontalInfoRow(
            icon: Icons.phone_outlined,
            title: 'Nomor Telepon',
            value: phoneNumber.isEmpty ? "-" : phoneNumber,
            isPhone: phoneNumber.isNotEmpty,
          ),
          const SizedBox(height: 12),
          _buildHorizontalInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Alamat',
            value:
                widget.package.address.isEmpty ? "-" : widget.package.address,
            isMultiLine: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(String orderDate) {
    if (_returnDetailData == null) return Container();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHorizontalInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Tanggal Order',
            value: orderDate,
          ),
          const SizedBox(height: 12),
          _buildHorizontalInfoRow(
            icon: Icons.access_time_outlined,
            title: 'Jadwal Pengiriman',
            value:
                DateFormat('HH:mm').format(widget.package.scheduledDelivery) +
                    ' WIB',
          ),
          const SizedBox(height: 12),
          _buildHorizontalInfoRow(
            icon: Icons.monetization_on_outlined,
            title: 'Total Pembayaran',
            value: moneyFormat.format(_returnDetailData!.totalPrice),
            valueColor: primaryColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    if (_returnDetailData == null) return Container();

    final items = _returnDetailData!.returnedItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count info
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
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.length} item',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total berat: ${_safeWeightWithUnit(_returnDetailData!.totalWeight, "kg")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status badge - Red for returned status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: returnStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Dikembalikan',
                    style: TextStyle(
                      color: returnStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List of items with cleaner, more consistent styling
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item number in circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Item details in a more compact layout
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name and return status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.unitName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: returnStatusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Return',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: returnStatusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                              height:
                                  8), // Item details in a single row with dividers
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                // Quantity
                                _buildCompactItemDetail(
                                  icon: Icons.format_list_numbered,
                                  label: 'Qty',
                                  value: _safeQuantity(item.quantity),
                                ),

                                // Vertical divider
                                VerticalDivider(
                                  width: 20,
                                  thickness: 1,
                                  color: Colors.grey.shade200,
                                ), // Unit with weight and metrics
                                _buildCompactItemDetail(
                                  icon: Icons.straighten,
                                  label: 'Unit',
                                  value: _safeWeightWithUnit(
                                      item.weight, item.unitMetrics),
                                ),

                                // Vertical divider
                                VerticalDivider(
                                  width: 20,
                                  thickness: 1,
                                  color: Colors.grey.shade200,
                                ),

                                // Price - highlighted
                                _buildCompactItemDetail(
                                  icon: Icons.monetization_on_outlined,
                                  label: 'Harga',
                                  value: moneyFormat.format(item.total),
                                  valueColor: primaryColor,
                                  iconColor: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Total section - clean and modern design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Nilai Barang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    moneyFormat.format(_returnDetailData!.totalPrice),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Compact item detail widget - more space-efficient
  Widget _buildCompactItemDetail({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: iconColor ?? Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiLine = false,
    bool isPhone = false,
    Color? valueColor,
    Color? iconColor,
    bool isBold = false,
  }) {
    final color = iconColor ?? primaryColor;

    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              isPhone
                  ? GestureDetector(
                      onTap: () {
                        // In a real app you would launch the phone app
                        // launch('tel:$value');
                      },
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isBold ? FontWeight.w600 : FontWeight.w500,
                          color: valueColor ?? Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                        color: valueColor ?? Colors.black87,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        child: SizedBox(
          height: 44, // Fixed height for better compactness
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PackageDetailScreen(package: widget.package),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lihat Detail Paket',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
