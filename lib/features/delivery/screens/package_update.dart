import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../models/package.dart';
import 'return_confirmation_screen.dart';
import 'document_confirmation_screen.dart';

class UpdatePackageScreen extends StatefulWidget {
  final Package package;

  const UpdatePackageScreen({Key? key, required this.package})
      : super(key: key);

  @override
  State<UpdatePackageScreen> createState() => _UpdatePackageScreenState();
}

class _UpdatePackageScreenState extends State<UpdatePackageScreen>
    with SingleTickerProviderStateMixin {
  late PackageStatus _selectedStatus;
  bool _isUpdating = false;
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Return specific fields
  String _returnReason = 'Barang tidak sesuai';
  List<String> _returnReasons = [
    'Barang tidak sesuai',
    'Pelanggan tidak ada di tempat',
    'Barang rusak',
    'Pelanggan menolak',
    'Alamat tidak ditemukan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with current package status
    _selectedStatus = widget.package.status;

    // Set the next logical step based on the current status
    if (widget.package.status == PackageStatus.onDelivery) {
      // Only allow Check-in as the next step from onDelivery
      _selectedStatus = PackageStatus.checkin;
    } else if (widget.package.status == PackageStatus.checkin) {
      // Default to checkout when already checked in
      _selectedStatus = PackageStatus.checkout;
    }

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
      begin: const Offset(0, 0.2),
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
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updatePackageStatus() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Simulate API call with a delay
      await Future.delayed(const Duration(seconds: 1));

      // If status is set to 'return', navigate to scan screen for OCR
      if (_selectedStatus == PackageStatus.returned) {
        _handleReturnFlow();
        return;
      }

      // For other status updates, just show success and pop back
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleReturnFlow() async {
    setState(() {
      _isUpdating = false;
    });

    try {
      final ImagePicker picker = ImagePicker();

      // Show dialog to confirm scan intent
      final bool? shouldScan = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scan Dokumen Return'),
          content: const Text(
            'Untuk mengembalikan paket, Anda perlu scan dokumen delivery untuk mengisi data return. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
              ),
              child: const Text(
                'Scan Dokumen',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldScan != true) {
        return;
      }

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
        // Arahkan ke document_confirmation_screen dengan foto yang diambil
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentConfirmationScreen(
                deliveryId: widget.package.id,
                capturedImages: [File(photo.path)],
              ),
            ),
          ).then((_) {
            // Pop current screen after return is processed
            Navigator.pop(context);
          });
        }
      } else {
        // User cancelled camera
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengambilan gambar dibatalkan"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
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

  void _showSuccessDialog() {
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
                  'Status Berhasil Diperbarui',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Status paket ${widget.package.id} telah berhasil diperbarui menjadi ${_getStatusText(_selectedStatus)}',
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
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to previous screen
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
                      'Kembali',
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

  String _getStatusText(PackageStatus status) {
    switch (status) {
      case PackageStatus.checkin:
        return 'Check-in';
      case PackageStatus.checkout:
        return 'Check-out';
      case PackageStatus.returned:
        return 'Return';
      case PackageStatus.onDelivery:
        return 'On Delivery';
    }
  }

  // Method to determine if the Return options should be shown
  bool _shouldShowReturnOptions() {
    return _selectedStatus == PackageStatus.returned;
  }

  // Logic to determine which status options to show based on current status
  List<PackageStatus> _getAvailableStatusOptions() {
    // Updating the workflow logic:
    if (widget.package.status == PackageStatus.onDelivery) {
      // When package is onDelivery, only allow updating to checkin
      return [PackageStatus.checkin];
    } else if (widget.package.status == PackageStatus.checkin) {
      // When package is checked in, allow updating to checkout or returned
      return [PackageStatus.checkout, PackageStatus.returned];
    } else {
      // If already checkout or returned, don't allow further changes
      return [widget.package.status];
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
          'Perbarui Status Paket',
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
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
                        _buildStatusUpdateSection(),
                        const SizedBox(height: 20),
                        if (_shouldShowReturnOptions())
                          _buildReturnReasonSection(),
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
              _buildStatusChip(widget.package.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.package.recipient,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
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
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.package.items,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.scale_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${widget.package.weight} kg',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.payment_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Rp ${widget.package.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateSection() {
    final availableStatuses = _getAvailableStatusOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perbarui Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF306424),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih status terbaru untuk paket ini',
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
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: availableStatuses.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final status = availableStatuses[index];
              final isSelected = _selectedStatus == status;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        _buildStatusIcon(status),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(status),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStatusDescription(status),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<PackageStatus>(
                          value: status,
                          groupValue: _selectedStatus,
                          activeColor: const Color(0xFF306424),
                          onChanged: (PackageStatus? value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReturnReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alasan Pengembalian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF306424),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih alasan mengapa paket ini dikembalikan',
          style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF306424).withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _returnReason,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF306424),
              ),
              isExpanded: true,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              items: _returnReasons.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _returnReason = newValue!;
                });
              },
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
        const Text(
          'Catatan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF306424),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tambahkan catatan tambahan (opsional)',
          style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Contoh: Diterima oleh satpam perumahan...',
            hintStyle: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF306424).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF306424)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Color(0xFF306424)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Color(0xFF306424),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updatePackageStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF306424),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      const Color(0xFF306424).withOpacity(0.5),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildStatusIcon(PackageStatus status) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (status) {
      case PackageStatus.checkin:
        iconData = Icons.login_outlined;
        iconColor = const Color(0xFFE67E22);
        bgColor = const Color(0xFFE67E22).withOpacity(0.1);
        break;
      case PackageStatus.checkout:
        iconData = Icons.check_circle_outline;
        iconColor = const Color(0xFF2ECC71);
        bgColor = const Color(0xFF2ECC71).withOpacity(0.1);
        break;
      case PackageStatus.returned:
        iconData = Icons.assignment_return_outlined;
        iconColor = const Color(0xFFE74C3C);
        bgColor = const Color(0xFFE74C3C).withOpacity(0.1);
        break;
      default:
        iconData = Icons.local_shipping_outlined;
        iconColor = const Color(0xFF3498DB);
        bgColor = const Color(0xFF3498DB).withOpacity(0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  String _getStatusDescription(PackageStatus status) {
    switch (status) {
      case PackageStatus.checkin:
        return 'Driver sudah sampai di lokasi pengiriman';
      case PackageStatus.checkout:
        return 'Paket sudah diterima oleh pelanggan';
      case PackageStatus.returned:
        return 'Paket dikembalikan dan tidak diterima oleh pelanggan';
      case PackageStatus.onDelivery:
        return 'Paket sedang dalam perjalanan ke alamat tujuan';
      default:
        return '';
    }
  }
}
