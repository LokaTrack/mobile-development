import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/package.dart';
import '../services/package_detail_service.dart';
import '../models/package_detail_model.dart';
import '../../../utils/datetime_helper.dart';

class PackageDetailScreen extends StatefulWidget {
  final Package package;

  const PackageDetailScreen({Key? key, required this.package})
      : super(key: key);

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final moneyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final PackageDetailService _packageDetailService = PackageDetailService();

  bool _isLoading = true;
  String? _errorMessage;
  PackageDetailData? _packageDetail;

  @override
  void initState() {
    super.initState();
    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Fetch the package details
    _fetchPackageDetails();
  }

  Future<void> _fetchPackageDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final packageDetail =
          await _packageDetailService.getPackageDetail(widget.package.id);

      setState(() {
        _packageDetail = packageDetail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Show loading state while fetching package details
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF5),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Background decorations
            _buildBackgroundDecorations(size),

            // Loading indicator
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
              ),
            ),
          ],
        ),
      );
    }

    // Show error state if there was an error
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF5),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Background decorations
            _buildBackgroundDecorations(size),

            // Error message
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[300],
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading package details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!.replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchPackageDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF306424),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } // Format date from API data or use package date as fallback
    String orderDate;
    try {
      final DateTime parsedDate = _packageDetail?.orderDate != null
          ? (DateTimeHelper.parseLocalDateTime(_packageDetail!.orderDate) ??
              widget.package.scheduledDelivery)
          : widget.package.scheduledDelivery;

      orderDate = DateFormat('dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      // Fallback to package date if parsing fails
      orderDate =
          DateFormat('dd MMMM yyyy').format(widget.package.scheduledDelivery);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background decorations
          _buildBackgroundDecorations(size),

          // Main content - Now using API data
          _buildMainContent(orderDate),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
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
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF306424),
            size: 16,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Detail Paket',
        style: TextStyle(
          color: Color(0xFF306424),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
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
              color: const Color(0xFF306424).withOpacity(0.08),
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
              color: const Color(0xFF306424).withOpacity(0.06),
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
              color: const Color(0xFF306424).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // Updated method to use API data
  Widget _buildMainContent(String orderDate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package ID and Status Card
          _buildStatusCard(),

          const SizedBox(height: 20),

          // Customer Information Section
          _buildSectionTitle('Informasi Penerima'),
          _buildCustomerInfoCard(),

          const SizedBox(height: 20),

          // Order Information Section
          _buildSectionTitle('Informasi Pesanan'),
          _buildOrderInfoCard(orderDate),

          const SizedBox(height: 20),

          // Items Section
          _buildSectionTitle('Daftar Item'),
          _buildItemsCard(),

          const SizedBox(height: 20),

          // Payment Summary Section
          _buildSectionTitle('Ringkasan Pembayaran'),
          _buildPaymentSummaryCard(),

          const SizedBox(height: 20),

          // Notes Section
          _buildSectionTitle('Catatan'),
          _buildNotesCard(),

          const SizedBox(height: 20),

          // Location Button
          _buildLocationButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF306424),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ID Display
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF306424).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF306424),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ID Paket',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        widget.package.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF306424),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Badge
              _buildStatusChip(widget.package.status),
            ],
          ),

          // Show delivery time or return reason based on status
          if (widget.package.status == PackageStatus.checkout)
            ..._buildDeliveryDetails()
          else if (widget.package.status == PackageStatus.returned)
            ..._buildReturnDetails(),
        ],
      ),
    );
  }

  List<Widget> _buildDeliveryDetails() {
    // Format the delivery time
    final deliveredDate = widget.package.deliveredAt != null
        ? DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(widget.package.deliveredAt!)
        : 'Not available';

    return [
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(
            Icons.check_circle_outlined,
            size: 16,
            color: Color(0xFF27AE60),
          ),
          const SizedBox(width: 8),
          Text(
            'Terkirim pada: $deliveredDate',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF27AE60),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildReturnDetails() {
    return [
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFC0392B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alasan pengembalian: ${widget.package.returningReason ?? "Tidak ada alasan yang dicatat"}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC0392B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildStatusChip(PackageStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case PackageStatus.onDelivery:
        bgColor = const Color(0xFF3498DB).withOpacity(0.15);
        textColor = const Color(0xFF2980B9);
        text = 'On Delivery';
        break;
      case PackageStatus.checkin:
        bgColor = const Color(0xFFE67E22).withOpacity(0.15);
        textColor = const Color(0xFFD35400);
        text = 'Check-in';
        break;
      case PackageStatus.checkout:
        bgColor = const Color(0xFF2ECC71).withOpacity(0.15);
        textColor = const Color(0xFF27AE60);
        text = 'Check-out';
        break;
      case PackageStatus.returned:
        bgColor = const Color(0xFFE74C3C).withOpacity(0.15);
        textColor = const Color(0xFFC0392B);
        text = 'Return';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Updated customer info card to use API data
  Widget _buildCustomerInfoCard() {
    final phone = _packageDetail?.phone ?? "-";
    final recipient = _packageDetail?.customer ?? widget.package.recipient;
    final address = _packageDetail?.address ?? widget.package.address;

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
          _buildInfoRow(
            icon: Icons.person_outline,
            title: 'Nama Penerima',
            value: recipient,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            title: 'Nomor Telepon',
            value: phone,
            isPhone: true,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Alamat',
            value: address,
            isMultiLine: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(String orderDate) {
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
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Tanggal Order',
            value: orderDate,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            title: 'Waktu Pengiriman',
            value:
                '${DateFormat('HH:mm').format(widget.package.scheduledDelivery)} WIB',
          ),
        ],
      ),
    );
  }

  // Updated items card to use API data
  Widget _buildItemsCard() {
    final items = _packageDetail?.items ?? [];
    final totalWeight = _packageDetail?.totalWeight ?? widget.package.weight;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items table header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Harga',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Item list from API
          if (items.isEmpty)
            // Fallback if items list is empty
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.package.items,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Text(
                    "-",
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 40),
                  Text(
                    moneyFormat.format(widget.package.totalAmount),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.quantity == item.quantity.toInt()
                              ? item.quantity.toInt().toString()
                              : item.quantity.toString(),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          moneyFormat.format(item.total),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )),

          const Divider(),

          // Total weight
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.scale_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Total Berat: $totalWeight kg',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated payment summary card to use API data
  Widget _buildPaymentSummaryCard() {
    final subTotal =
        _packageDetail?.subTotal ?? widget.package.totalAmount.toDouble();
    final discount = _packageDetail?.discount ?? 0.0;
    final shipping = _packageDetail?.shipping ?? 0.0;
    final totalPrice =
        _packageDetail?.totalPrice ?? widget.package.totalAmount.toDouble();

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
          _buildPriceRow(
            label: 'Sub Total',
            amount: subTotal,
          ),
          const SizedBox(height: 10),
          _buildPriceRow(
            label: 'Diskon',
            amount: discount,
            isDiscount: true,
          ),
          const SizedBox(height: 10),
          _buildPriceRow(
            label: 'Biaya Pengiriman',
            amount: shipping,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildPriceRow(
            label: 'Total',
            amount: totalPrice,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required double amount,
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: isTotal ? const Color(0xFF306424) : Colors.black87,
          ),
        ),
        Text(
          isDiscount
              ? '- ${moneyFormat.format(amount)}'
              : moneyFormat.format(amount),
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDiscount
                ? const Color(0xFFC0392B)
                : (isTotal ? const Color(0xFF306424) : Colors.black87),
          ),
        ),
      ],
    );
  }

  // Updated notes card to use API data
  Widget _buildNotesCard() {
    final notes = _packageDetail?.orderNotes ?? widget.package.notes;
    final hasNotes = notes.isNotEmpty;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 18,
                color: hasNotes ? const Color(0xFF306424) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasNotes ? notes : 'Tidak ada catatan',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasNotes ? Colors.black87 : Colors.grey,
                    fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Updated location button to use API data
  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Use address map URL from API if available, otherwise fallback to address
          if (_packageDetail?.addressMapUrl != null &&
              _packageDetail!.addressMapUrl.isNotEmpty) {
            _openAddressMapUrl(_packageDetail!.addressMapUrl);
          } else {
            _openMapsWithAddress(
                _packageDetail?.address ?? widget.package.address);
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF306424),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.location_on),
        label: const Text(
          'Lihat Lokasi Pengiriman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiLine = false,
    bool isPhone = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF306424).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF306424), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              isPhone
                  ? GestureDetector(
                      onTap: () => _callPhoneNumber(value),
                      child: Row(
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF306424),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.call_outlined,
                            size: 16,
                            color: Color(0xFF306424),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _callPhoneNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll('-', '');
    final url = 'tel:$cleanNumber';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackbar('Tidak dapat melakukan panggilan');
    }
  }

  void _openMapsWithAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    String url;

    if (Platform.isAndroid) {
      url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    } else if (Platform.isIOS) {
      url = 'https://maps.apple.com/?q=$encodedAddress';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackbar('Tidak dapat membuka peta');
    }
  }

  // New method to open map URL directly from API
  void _openAddressMapUrl(String mapUrl) async {
    if (await canLaunch(mapUrl)) {
      await launch(mapUrl);
    } else {
      // Fallback to address if map URL cannot be opened
      _openMapsWithAddress(_packageDetail?.address ?? widget.package.address);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF306424),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Helper extension for capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
}
