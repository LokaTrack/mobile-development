import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package_detail.dart';

class AllDeliveriesScreen extends StatefulWidget {
  const AllDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<AllDeliveriesScreen> createState() => _AllDeliveriesScreenState();
}

class _AllDeliveriesScreenState extends State<AllDeliveriesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  // Dummy data - Replace with actual data from API
  final List<Map<String, String>> _allDeliveries = [
    {
      'id': 'PKT-001',
      'customer': 'Cornelius Yuli',
      'address': 'Jl. Kenanga No. 15, Bandung',
      'status': 'shipping',
      'date': '2024-03-15',
    },
    {
      'id': 'PKT-002',
      'customer': 'Shaquille Arriza',
      'address': 'Jl. Anggrek No. 7, Bandung',
      'status': 'shipping',
      'date': '2024-03-15',
    },
    {
      'id': 'PKT-003',
      'customer': 'Devina',
      'address': 'Jl. Mawar No. 23, Bandung',
      'status': 'shipping',
      'date': '2024-03-15',
    },
    {
      'id': 'PKT-004',
      'customer': 'Ahmad Zaky',
      'address': 'Jl. Melati No. 45, Bandung',
      'status': 'completed',
      'date': '2024-03-14',
    },
    {
      'id': 'PKT-005',
      'customer': 'Sarah Linda',
      'address': 'Jl. Dahlia No. 12, Bandung',
      'status': 'completed',
      'date': '2024-03-14',
    },
    {
      'id': 'PKT-006',
      'customer': 'Budi Santoso',
      'address': 'Jl. Kamboja No. 8, Bandung',
      'status': 'return',
      'date': '2024-03-14',
    },
  ];

  List<Map<String, String>> get filteredDeliveries {
    return _allDeliveries.where((delivery) {
      final matchesSearch =
          delivery['id']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          delivery['customer']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          delivery['address']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      if (_selectedFilter == 'all') return matchesSearch;
      return matchesSearch && delivery['status'] == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Pengiriman',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: ClipRRect(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 160),
              child: RefreshIndicator(
                color: const Color(0xFF306424),
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDeliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = filteredDeliveries[index];
                    final bool isLastItem =
                        index == filteredDeliveries.length - 1;
                    return Column(
                      children: [
                        _buildDeliveryItem(delivery),
                        if (!isLastItem) const SizedBox(height: 15),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PhysicalModel(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Column(
                  children: [
                    // Search Bar with padding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari pengiriman...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF306424),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    // Filter Chips with better spacing
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              _buildFilterChip('Semua', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Dikirim', 'shipping'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Selesai', 'completed'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Retur', 'return'),
                              const SizedBox(width: 20),
                            ],
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF306424),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF306424),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFF306424),
          width: isSelected ? 0 : 1,
        ),
      ),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F6E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF306424),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery['id']!,
                        style: const TextStyle(
                          color: Color(0xFF306424),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        delivery['date']!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
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
          const SizedBox(height: 15),
          Text(
            delivery['customer']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
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
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PackageDetailScreen(
                            packageData: {
                              'Order No': delivery['id']!,
                              'Order Date': delivery['date']!,
                              'Customer': delivery['customer']!,
                              'Address': delivery['address']!,
                              'Phone': '-',
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
                              ],
                              'Sub Total': 'Rp 348.000',
                              'Discount': 'Rp 0',
                              'Shipping': 'Rp 0',
                              'Total': 'Rp 348.000',
                            },
                          ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE9F6E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
