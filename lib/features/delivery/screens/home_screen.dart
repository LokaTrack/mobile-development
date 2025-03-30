import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/history_screen.dart';
import '../screens/package_detail.dart';
import 'settings_screen.dart';
import '../screens/OCR_confirmation.dart';
import '../screens/all_deliveries_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'add_package_confirmation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
                            const SizedBox(height: 20),
                            _buildWelcomeSection(),
                            const SizedBox(height: 20),
                            _buildDeliverySummary(),
                            const SizedBox(height: 20),
                            _buildDeliveryTitle(),
                            const SizedBox(height: 10),
                            _buildDeliveryList(),
                            const SizedBox(height: 20),
                            const SizedBox(height: 100),
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

                          // Navigate to Setting Screen
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
                'LokaTrack',
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

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Halo, Driver!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF306424),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat datang di aplikasi tracking pengiriman',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySummary() {
    return Container(
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
            'Ringkasan Pengiriman',
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
                title: 'Dikirim',
                value: '28',
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
                value: '2',
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
                value: '93%',
                color: Colors.white,
              ),
            ],
          ),
        ],
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

  Widget _buildDeliveryTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pengiriman Hari Ini',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllDeliveriesScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              color: Color(0xFF306424),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryList() {
    // Daftar contoh pengiriman
    final deliveries = [
      {
        'id': 'PKT-001',
        'customer': 'Cornelius Yuli',
        'address': 'Jl. Kenanga No. 15, Bandung',
        'status': 'shipping',
      },
      {
        'id': 'PKT-002',
        'customer': 'Shaquille Arriza',
        'address': 'Jl. Anggrek No. 7, Bandung',
        'status': 'shipping',
      },
      {
        'id': 'PKT-003',
        'customer': 'Devina',
        'address': 'Jl. Mawar No. 23, Bandung',
        'status': 'completed',
      },
    ];

    return Column(
      children:
          deliveries.map((delivery) => _buildDeliveryItem(delivery)).toList(),
    );
  }

  Widget _buildDeliveryItem(Map<String, String> delivery) {
    Color statusColor;
    String statusText;

    switch (delivery['status']) {
      case 'shipping':
        statusColor = Colors.blue;
        statusText = 'Dikirim';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'return':
        statusColor = Colors.red;
        statusText = 'Retur';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak Diketahui';
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Icon
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF306424),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Package Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      delivery['id']!,
                      style: const TextStyle(
                        color: Color(0xFF306424),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  delivery['customer']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
                        delivery['address']!,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to Package Detail Screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => PackageDetailScreen(
                                  packageData: {
                                    'Order No': delivery['id']!,
                                    'Order Date':
                                        '12/03/2025', // Example static date
                                    'Customer': delivery['customer']!,
                                    'Address': delivery['address']!,
                                    'Phone':
                                        '-', // Add phone number if available
                                    'Items': [
                                      {
                                        'name': 'Brokoli Gundul',
                                        'qty': 5,
                                        'unit': 'Kg',
                                        'total': 285000,
                                      },
                                      {
                                        'name': 'Caisim',
                                        'qty': 2,
                                        'unit': 'Kg',
                                        'total': 63000,
                                      },
                                      {
                                        'name': 'Daun Cameo',
                                        'qty': 3,
                                        'unit': 'Kg',
                                        'total': 70000,
                                      },
                                      {
                                        'name': 'Kecambah',
                                        'qty': 500,
                                        'unit': 'g',
                                        'total': 16250,
                                      },
                                      // Add more items as needed
                                    ],
                                    'Sub Total': 'Rp 434.250',
                                    'Discount': 'Rp 0',
                                    'Shipping': 'Rp 0',
                                    'Total': 'Rp 434.250',
                                  },
                                ),
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
          _buildNavItem(0, Icons.home_rounded, 'Beranda', () {}),
          _buildCenterScanButton(),
          _buildNavItem(2, Icons.history_rounded, 'Riwayat', () {
            // Navigate to History Screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
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
        onTap(); // Call the provided onTap callback
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

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow sheet to be scrollable
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
                  const SizedBox(height: 20), // Add bottom padding
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
}
