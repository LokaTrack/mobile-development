import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/package_detail.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> deliveryData;

  const HistoryDetailScreen({Key? key, required this.deliveryData})
    : super(key: key);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeliveryStatusCard(),
                      const SizedBox(height: 20),
                      _buildDeliveryTimeline(),
                      const SizedBox(height: 20),
                      _buildDeliveryDetails(),
                      const SizedBox(height: 20),
                      _buildActionButtons(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 40,
              width: 40,
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
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF306424),
                  size: 20,
                ),
              ),
            ),
          ),

          // Screen Title
          Text(
            'Riwayat Pengiriman ${deliveryData['id']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF306424),
            ),
          ),

          // Placeholder for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (deliveryData['status']) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Pengiriman Berhasil';
        break;
      case 'returned':
        statusColor = Colors.orange;
        statusIcon = Icons.assignment_return_outlined;
        statusText = 'Paket Dikembalikan';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Status Tidak Diketahui';
    }

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
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Paket ${deliveryData['customer']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
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
            'Proses Pengiriman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Horizontal line
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Container(height: 2, color: Colors.grey[300]),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimelineIndicator(
                          title: 'Dikirim',
                          date: '15 Mar',
                          time: '09:00 WIB',
                          isActive: deliveryData['status'] == 'completed',
                          isFirst: true,
                        ),
                        _buildTimelineIndicator(
                          title: 'Dalam Perjalanan',
                          date: '15 Mar',
                          time: '',
                          isActive: deliveryData['status'] == 'completed',
                          isMiddle: true,
                        ),
                        _buildTimelineIndicator(
                          title:
                              deliveryData['status'] == 'returned'
                                  ? 'Return'
                                  : 'Diterima',
                          date: '15 Mar',
                          time: '11:45 WIB',
                          isActive: deliveryData['status'] == 'completed',
                          isLast: true,
                          isReturned: deliveryData['status'] == 'returned',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildDurationInfo(),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator({
    required String title,
    required String date,
    required String time,
    bool isActive = false,
    bool isFirst = false,
    bool isMiddle = false,
    bool isLast = false,
    bool isReturned = false,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isActive
                    ? const Color(0xFF306424)
                    : (isReturned ? Colors.orange : Colors.grey[300]),
          ),
          child: Center(
            child: Icon(
              isFirst
                  ? Icons.local_shipping_outlined
                  : isMiddle
                  ? Icons.route_outlined
                  : (isReturned
                      ? Icons.assignment_return_outlined
                      : Icons.check_circle_outline),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color:
                isActive
                    ? const Color(0xFF306424)
                    : (isReturned ? Colors.orange : Colors.grey),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 5),
        Column(
          children: [
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6E5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF306424)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waktu Pengiriman',
                  style: TextStyle(
                    color: Color(0xFF306424),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: 2 jam 45 menit',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails() {
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
            'Detail Pengiriman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            icon: Icons.receipt_long_outlined,
            label: 'Nomor Paket',
            value: deliveryData['id'],
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.person_outline,
            label: 'Penerima',
            value: deliveryData['customer'],
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: deliveryData['address'],
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.line_weight,
            label: 'Berat Paket',
            value: deliveryData['weight'],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF306424), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Use the delivery data to populate package details
              final packageData = {
                'Order No': deliveryData['id'] ?? '',
                'Order Date':
                    deliveryData['date'] ?? '15/03/2024', // Default date
                'Customer': deliveryData['customer'] ?? '',
                'Address': deliveryData['address'] ?? '',
                'Phone': deliveryData['phone'] ?? '-', // Default phone
                'Sub Total': deliveryData['subtotal'] ?? 'Rp 434.250',
                'Discount': deliveryData['discount'] ?? 'Rp 0',
                'Shipping': deliveryData['shipping'] ?? 'Rp 0',
                'Total': deliveryData['total'] ?? 'Rp 434.250',
                'Items':
                    deliveryData['items'] ??
                    [
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
                      // Add default items if not provided
                    ],
              };

              // Navigate to package detail screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          PackageDetailScreen(packageData: packageData),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF306424),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_outlined, size: 20),
                SizedBox(width: 10),
                Text(
                  'Detail Paket',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
