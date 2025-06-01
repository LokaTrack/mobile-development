import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/package.dart';
import '../models/delivery_model.dart';
import '../services/delivery_service.dart';
import 'package:intl/intl.dart';
import 'package_detail.dart';
import 'package_update.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with SingleTickerProviderStateMixin {
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter states
  List<PackageStatus> _selectedStatusFilters = [];
  DateTimeRange? _selectedDateRange;
  String _selectedSortOption = 'Terbaru';

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // API related state
  final DeliveryService _deliveryService = DeliveryService();
  List<DeliveryItem> _allDeliveries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track if filters are active
  bool get _isFilterActive =>
      _selectedStatusFilters.isNotEmpty || _selectedDateRange != null;
  // Filtered packages list - now converted from DeliveryItem to Package for compatibility
  List<Package> _filteredPackages = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDeliveries();

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadDeliveries() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final deliveriesResponse = await _deliveryService.getAllDeliveries();

      setState(() {
        _allDeliveries = deliveriesResponse.data.deliveries;
        // Apply existing filters after loading new data
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading deliveries: $e');
    }
  }

  // Convert DeliveryItem to Package for UI compatibility
  void _convertDeliveriesToPackages() {
    _filteredPackages = _allDeliveries.map((delivery) {
      return Package(
        id: delivery.orderNo,
        recipient: delivery.customer,
        address: delivery.address,
        status: delivery.packageStatus,
        items: delivery.formattedItems,
        scheduledDelivery: delivery.deliveryStartTime,
        totalAmount: delivery.totalPrice.toInt(),
        weight: delivery.totalWeight,
        notes: delivery.orderNotes,
        // Set deliveredAt based on checkOutTime if available
        deliveredAt: delivery.checkOutTime,
        // Set other optional fields as needed
        rating: delivery.packageStatus == PackageStatus.checkout ? 5 : null,
      );
    }).toList();

    // Apply default sorting (newest first)
    _sortPackages(_selectedSortOption);
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

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Apply all filters and search
  void _applyFilters() {
    if (_allDeliveries.isEmpty) return;

    // Convert deliveries to packages first
    List<Package> allPackages = _allDeliveries.map((delivery) {
      return Package(
        id: delivery.orderNo,
        recipient: delivery.customer,
        address: delivery.address,
        status: delivery.packageStatus,
        items: delivery.formattedItems,
        scheduledDelivery: delivery.deliveryStartTime,
        totalAmount: delivery.totalPrice.toInt(),
        weight: delivery.totalWeight,
        notes: delivery.orderNotes,
        deliveredAt: delivery.checkOutTime,
        rating: delivery.packageStatus == PackageStatus.checkout ? 5 : null,
      );
    }).toList();

    setState(() {
      _filteredPackages = allPackages.where((package) {
        // Apply status filter
        if (_selectedStatusFilters.isNotEmpty &&
            !_selectedStatusFilters.contains(package.status)) {
          return false;
        }

        // Apply date range filter
        if (_selectedDateRange != null) {
          final packageDate = DateTime(
            package.scheduledDelivery.year,
            package.scheduledDelivery.month,
            package.scheduledDelivery.day,
          );
          final startDate = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final endDate = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
          );

          if (packageDate.isBefore(startDate) || packageDate.isAfter(endDate)) {
            return false;
          }
        }

        // Apply search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return package.id.toLowerCase().contains(query) ||
              package.recipient.toLowerCase().contains(query) ||
              package.address.toLowerCase().contains(query) ||
              package.items.toLowerCase().contains(query);
        }

        return true;
      }).toList();

      // Apply sorting
      _sortPackages(_selectedSortOption);
    });
  }

  // Sort packages based on selected option
  void _sortPackages(String sortOption) {
    setState(() {
      switch (sortOption) {
        case 'Terbaru':
          _filteredPackages.sort(
            (a, b) => b.scheduledDelivery.compareTo(a.scheduledDelivery),
          );
          break;
        case 'Terlama':
          _filteredPackages.sort(
            (a, b) => a.scheduledDelivery.compareTo(b.scheduledDelivery),
          );
          break;
        case 'A-Z':
          _filteredPackages.sort(
            (a, b) =>
                a.recipient.toLowerCase().compareTo(b.recipient.toLowerCase()),
          );
          break;
        case 'Z-A':
          _filteredPackages.sort(
            (a, b) =>
                b.recipient.toLowerCase().compareTo(a.recipient.toLowerCase()),
          );
          break;
        case 'Harga Tertinggi':
          _filteredPackages.sort(
            (a, b) => b.totalAmount.compareTo(a.totalAmount),
          );
          break;
        case 'Harga Terendah':
          _filteredPackages.sort(
            (a, b) => a.totalAmount.compareTo(b.totalAmount),
          );
          break;
      }
      _selectedSortOption = sortOption;
    });
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _selectedStatusFilters = [];
      _selectedDateRange = null;
      _searchController.clear();
      _searchQuery = '';
      _selectedSortOption = 'Terbaru';
      _convertDeliveriesToPackages(); // Use the converted packages
    });
  }

  // Open date range picker
  Future<void> _selectDateRange() async {
    final initialDateRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF306424),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
        _applyFilters();
      });
    }
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottom sheet header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Paket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Filter options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status Filter
                      const Text(
                        'Status Paket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusFilterChip(
                            status: PackageStatus.onDelivery,
                            label: 'On Delivery',
                            setModalState: setModalState,
                          ),
                          _buildStatusFilterChip(
                            status: PackageStatus.checkin,
                            label: 'Check-in',
                            setModalState: setModalState,
                          ),
                          _buildStatusFilterChip(
                            status: PackageStatus.checkout,
                            label: 'Check-out',
                            setModalState: setModalState,
                          ),
                          _buildStatusFilterChip(
                            status: PackageStatus.returned,
                            label: 'Return',
                            setModalState: setModalState,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date Range Filter
                      const Text(
                        'Rentang Tanggal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await _selectDateRange();
                          _showFilterBottomSheet();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(
                                0xFF306424,
                              ).withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDateRange == null
                                    ? 'Pilih Rentang Tanggal'
                                    : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                                style: TextStyle(
                                  color: _selectedDateRange == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                              Icon(
                                Icons.calendar_month,
                                color: _selectedDateRange == null
                                    ? Colors.grey.shade600
                                    : const Color(0xFF306424),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sort By
                      const Text(
                        'Urutkan Berdasarkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSortOptionList(setModalState),
                    ],
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF306424),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFF306424)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF306424),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Terapkan',
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
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
    );
  }

  // Build status filter chip
  Widget _buildStatusFilterChip({
    required PackageStatus status,
    required String label,
    required StateSetter setModalState,
  }) {
    final bool isSelected = _selectedStatusFilters.contains(status);

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
      switch (status) {
        case PackageStatus.onDelivery:
          bgColor = const Color(0xFF3498DB).withValues(alpha: 0.2);
          textColor = const Color(0xFF2980B9);
          borderColor = const Color(0xFF2980B9);
          break;
        case PackageStatus.checkin:
          bgColor = const Color(0xFFE67E22).withValues(alpha: 0.2);
          textColor = const Color(0xFFD35400);
          borderColor = const Color(0xFFD35400);
          break;
        case PackageStatus.checkout:
          bgColor = const Color(0xFF2ECC71).withValues(alpha: 0.2);
          textColor = const Color(0xFF27AE60);
          borderColor = const Color(0xFF27AE60);
          break;
        case PackageStatus.returned:
          bgColor = const Color(0xFFE74C3C).withValues(alpha: 0.2);
          textColor = const Color(0xFFC0392B);
          borderColor = const Color(0xFFC0392B);
          break;
      }
    } else {
      bgColor = Colors.transparent;
      textColor = Colors.grey.shade600;
      borderColor = Colors.grey.shade400;
    }

    return GestureDetector(
      onTap: () {
        setModalState(() {
          if (isSelected) {
            _selectedStatusFilters.remove(status);
          } else {
            _selectedStatusFilters.add(status);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Build sort options list
  Widget _buildSortOptionList(StateSetter setModalState) {
    final sortOptions = [
      'Terbaru',
      'Terlama',
      'A-Z',
      'Z-A',
      'Harga Tertinggi',
      'Harga Terendah',
    ];

    return Column(
      children: sortOptions.map((option) {
        final isSelected = _selectedSortOption == option;
        return InkWell(
          onTap: () {
            setModalState(() {
              _selectedSortOption = option;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  option,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF306424) : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF306424),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat daftar pengiriman...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Build error state
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
              'Gagal memuat data pengiriman',
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
              onPressed: _loadDeliveries,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF306424),
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

  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada paket ditemukan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Build package list
  Widget _buildPackageList() {
    return RefreshIndicator(
      color: const Color(0xFF306424),
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _filteredPackages.length,
        itemBuilder: (context, index) {
          final package = _filteredPackages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPackageCard(package),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          'Daftar Paket',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                // Search box
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari paket, penerima, atau alamat...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                color: Colors.grey.shade500,
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _applyFilters();
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter button
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _isFilterActive
                            ? const Color(0xFF306424)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: Icon(
                          Icons.filter_list,
                          color: _isFilterActive
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                        tooltip: 'Filter',
                      ),
                    ),
                    if (_isFilterActive)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active filters
          if (_isFilterActive || _selectedSortOption != 'Terbaru')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Sort chip
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF306424,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sort,
                                      size: 16,
                                      color: Color(0xFF306424),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedSortOption,
                                      style: const TextStyle(
                                        color: Color(0xFF306424),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Date range chip
                              if (_selectedDateRange != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF306424,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.date_range,
                                        size: 16,
                                        color: Color(0xFF306424),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                                        style: const TextStyle(
                                          color: Color(0xFF306424),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Status filters
                              ..._selectedStatusFilters.map((status) {
                                String label;
                                Color color;

                                switch (status) {
                                  case PackageStatus.onDelivery:
                                    label = 'On Delivery';
                                    color = const Color(0xFF2980B9);
                                    break;
                                  case PackageStatus.checkin:
                                    label = 'Check-in';
                                    color = const Color(0xFFE67E22);
                                    break;
                                  case PackageStatus.checkout:
                                    label = 'Check-out';
                                    color = const Color(0xFF27AE60);
                                    break;
                                  case PackageStatus.returned:
                                    label = 'Return';
                                    color = const Color(0xFFC0392B);
                                    break;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),

                      // Clear filters button
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ), // Package list
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _filteredPackages.isEmpty
                          ? _buildEmptyState()
                          : _buildPackageList(),
            ),
          ),
        ],
      ),
    );
  }

  // Build custom package card
  Widget _buildPackageCard(Package package) {
    // Define colors based on status
    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (package.status) {
      case PackageStatus.onDelivery:
        statusColor = const Color(0xFF2980B9);
        statusBgColor = const Color(0xFF3498DB).withValues(alpha: 0.15);
        statusText = 'On Delivery';
        break;
      case PackageStatus.checkin:
        statusColor = const Color(0xFFE67E22);
        statusBgColor = const Color(0xFFE67E22).withValues(alpha: 0.15);
        statusText = 'Check-in';
        break;
      case PackageStatus.checkout:
        statusColor = const Color(0xFF27AE60);
        statusBgColor = const Color(0xFF2ECC71).withValues(alpha: 0.15);
        statusText = 'Check-out';
        break;
      case PackageStatus.returned:
        statusColor = const Color(0xFFC0392B);
        statusBgColor = const Color(0xFFE74C3C).withValues(alpha: 0.15);
        statusText = 'Return';
        break;
    }

    // Format date
    final scheduledDateFormatted = DateFormat(
      'dd MMM yyyy',
    ).format(package.scheduledDelivery);

    // Format currency
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final formattedAmount = formatCurrency.format(package.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigate to package detail screen
            // Navigator.push(context, MaterialPageRoute(builder: (context) => PackageDetailScreen(package: package)));
          },
          splashColor: const Color(0xFF306424).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF306424).withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with ID and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                          color: Color(0xFF306424),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          package.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF306424),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recipient and address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column with icons
                    Column(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 14),
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Right column with text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.recipient,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            package.address,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divider
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // Bottom info section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scheduled date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          scheduledDateFormatted,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // Total amount
                    Text(
                      formattedAmount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF306424),
                      ),
                    ),
                  ],
                ),

                // Items preview (only if items exist)
                if (package.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          package.items,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Delivered information (only for delivered packages)
                if (package.status == PackageStatus.checkout &&
                    package.deliveredAt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF27AE60),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dikirim: ${DateFormat('dd MMM, HH:mm').format(package.deliveredAt!)}',
                            style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                // Returned reason (only for returned packages)
                if (package.status == PackageStatus.returned &&
                    package.returningReason != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFFC0392B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Alasan: ${package.returningReason}',
                          style: const TextStyle(
                            color: Color(0xFFC0392B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons based on status
                if (package.status == PackageStatus.onDelivery ||
                    package.status == PackageStatus.checkin) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UpdatePackageScreen(package: package),
                              ),
                            );
                          },
                          icon: const Icon(Icons.update, size: 16),
                          label: const Text(
                            'Update',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF306424),
                            side: const BorderSide(color: Color(0xFF306424)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to appropriate detail screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PackageDetailScreen(package: package),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text(
                            'Detail',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF306424),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (package.status == PackageStatus.checkout ||
                    package.status == PackageStatus.returned) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to appropriate detail screen based on status
                        if (package.status == PackageStatus.returned) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PackageDetailScreen(package: package),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PackageDetailScreen(package: package),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text(
                        'Detail',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF306424),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
