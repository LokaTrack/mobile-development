import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/history_detail.dart';
import 'settings_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../screens/OCR_confirmation.dart';
import 'add_package_confirmation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedIndex = 4; // Set to History tab
  DateTime? _selectedDate;
  String? _selectedStatus;
  List<Map<String, dynamic>> _filteredHistory = [];

  // Sample delivery history data
  final List<Map<String, dynamic>> _deliveryHistory = [
    {
      'id': 'PKT-001',
      'customer': 'Cornelius Yuli',
      'date': '15 Mar 2024',
      'address': 'Jl. Kenanga No. 15, Bandung',
      'status': 'completed',
      'weight': '5 kg',
      'revenue': 'Rp 434.250',
    },
    {
      'id': 'PKT-002',
      'customer': 'Shaquille Arriza',
      'date': '14 Mar 2024',
      'address': 'Jl. Anggrek No. 7, Bandung',
      'status': 'completed',
      'weight': '3 kg',
      'revenue': 'Rp 434.250',
    },
    {
      'id': 'PKT-003',
      'customer': 'Devina',
      'date': '13 Mar 2024',
      'address': 'Jl. Mawar No. 23, Bandung',
      'status': 'returned',
      'weight': '2 kg',
      'revenue': 'Rp 434.250',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredHistory = List.from(_deliveryHistory);
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color and brightness
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 10),
                _buildHistorySummary(),
                const SizedBox(height: 20),
                _buildHistoryTitle(),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF306424),
                    onRefresh: () async {
                      // Implement refresh logic
                      await Future.delayed(const Duration(seconds: 2));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHistoryList(),
                            const SizedBox(
                              height: 100,
                            ), // Extra space for bottom nav
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Custom Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCustomBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show profile dropdown
  void _showProfileDropdown(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: offset.dy + renderBox.size.height,
              right: screenWidth - (offset.dx + renderBox.size.width),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDropdownItem(
                        icon: Icons.settings,
                        text: 'Settings',
                        onTap: () {
                          // Close the dropdown
                          Navigator.pop(context);

                          // Navigate to Update Setting Screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildDropdownItem(
                        icon: Icons.logout,
                        text: 'Logout',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () {
                          // Show logout confirmation dialog
                          _showLogoutConfirmationDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build dropdown menu items
  Widget _buildDropdownItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFF306424), size: 22),
            const SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                color: textColor ?? Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build divider
  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.withOpacity(0.2),
      indent: 15,
      endIndent: 15,
    );
  }

  // Logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF306424),
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin logout dari aplikasi?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF306424),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                // Implement logout logic
                // Clear any stored tokens, user data, etc.
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and App Name
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/lokatani_logo.png',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF306424),
                ),
              ),
            ],
          ),
          // Profile Section with Hamburger Menu
          Builder(
            builder:
                (context) => GestureDetector(
                  onTap: () => _showProfileDropdown(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hamburger Menu Icon
                        const Icon(
                          Icons.menu,
                          color: Color(0xFF306424),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        // Profile Image
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF306424).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _buildProfileImage(),
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

  Widget _buildProfileImage() {
    // TODO: Replace this with actual user profile image logic
    bool hasProfileImage =
        true; // This will be determined by your backend logic

    if (hasProfileImage) {
      return Image.asset(
        'assets/images/default_profile.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF306424), size: 20),
          );
        },
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Color(0xFF306424), size: 20),
      );
    }
  }

  Widget _buildHistorySummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF306424), Color(0xFF408534)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF306424).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Pengiriman',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSummaryItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Total Paket',
                  value: '45',
                  color: Colors.white,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                ),
                _buildSummaryItem(
                  icon: Icons.check_circle_outline,
                  title: 'Sukses',
                  value: '42',
                  color: Colors.white,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                ),
                _buildSummaryItem(
                  icon: Icons.assignment_return_outlined,
                  title: 'Return',
                  value: '3',
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Riwayat Pengiriman',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Filter Button
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF306424),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._filteredHistory
            .map((delivery) => _buildHistoryItem(delivery))
            .toList(),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> delivery) {
    Color statusColor;
    IconData statusIcon;

    switch (delivery['status']) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'returned':
        statusColor = Colors.orange;
        statusIcon = Icons.assignment_return_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                delivery['id'],
                style: const TextStyle(
                  color: Color(0xFF306424),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    delivery['status'] == 'completed'
                        ? 'Selesai'
                        : 'Dikembalikan',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery['customer'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            delivery['address'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    delivery['date'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    delivery['revenue'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF306424),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.line_weight, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    'Berat: ${delivery['weight']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to History Detail Screen with specific delivery data
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              HistoryDetailScreen(deliveryData: delivery),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  backgroundColor: const Color(0xFFE9F6E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(
                    color: Color(0xFF306424),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Beranda', () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }),
          _buildCenterScanButton(),
          _buildNavItem(4, Icons.history_rounded, 'Riwayat', () {
            // Current screen, do nothing
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF306424) : Colors.grey,
            size: isSelected ? 28 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF306424) : Colors.grey,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterScanButton() {
    return GestureDetector(
      onTap: _showScanOptions,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF306424),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF306424).withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.document_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Pilih Tipe Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF306424),
                      ),
                    ),
                  ),
                  _buildScanOptionButton(
                    'Tambah Pengiriman Baru',
                    Icons.add_box_outlined,
                    () => _handleScanOption(true),
                  ),
                  const SizedBox(height: 10),
                  _buildScanOptionButton(
                    'Perbarui Status Pengiriman',
                    Icons.update_outlined,
                    () => _handleScanOption(false),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanOptionButton(
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE9F6E5),
          foregroundColor: const Color(0xFF306424),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScanOption(bool isNewDelivery) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null && mounted) {
        if (isNewDelivery) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AddPackageConfirmationScreen(imageFile: File(photo.path)),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      OCRConfirmationScreen(imageFile: File(photo.path)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredHistory =
          _deliveryHistory.where((delivery) {
            bool matchesDate = true;
            bool matchesStatus = true;

            if (_selectedDate != null) {
              final deliveryDate = DateTime.parse(
                delivery['date']
                    .split(' ')
                    .reversed
                    .join('-')
                    .replaceAll('Mar', '03'),
              );
              matchesDate =
                  deliveryDate.year == _selectedDate!.year &&
                  deliveryDate.month == _selectedDate!.month &&
                  deliveryDate.day == _selectedDate!.day;
            }

            if (_selectedStatus != null) {
              matchesStatus = delivery['status'] == _selectedStatus;
            }

            return matchesDate && matchesStatus;
          }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Filter Pengiriman',
                style: TextStyle(
                  color: Color(0xFF306424),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Filter
                  const Text(
                    'Tanggal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF306424),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Pilih Tanggal'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              color:
                                  _selectedDate == null
                                      ? Colors.grey
                                      : Colors.black,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status Filter
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Pilih Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Selesai'),
                      ),
                      DropdownMenuItem(
                        value: 'returned',
                        child: Text('Dikembalikan'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                    },
                  ),
                ],
              ),
              actions: [
                // Reset Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _selectedStatus = null;
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // Apply Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF306424),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
