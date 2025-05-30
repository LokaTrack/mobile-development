import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/package.dart';
import '../widgets/filter_chip.dart';
import '../../../core/constants/colors.dart';
import '../../../features/profile/services/profile_service.dart';
import '../../../features/profile/models/user_profile_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../screens/add_package_confirmation.dart';
import 'package_detail.dart';
import 'return_detail.dart';
import 'document_confirmation_screen.dart';
import 'package_update.dart';
import 'package:shimmer/shimmer.dart';
import '../services/history_service.dart';
import '../models/history_model.dart';
import '../services/ocr_service.dart';
import '../models/delivery_detail_model.dart'; // Added missing import for DeliveryDetailData
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import '../services/delivery_detail_service.dart'; // Add missing import for DeliveryDetailService
import '../../../utils/image_cache_helper.dart';
import '../../../utils/datetime_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Check-out', 'Return'];

  final ProfileService _profileService = ProfileService();
  final HistoryService _historyService = HistoryService();
  final DeliveryDetailService _deliveryDetailService = DeliveryDetailService();
  final DashboardService _dashboardService = DashboardService();
  UserProfile? _userProfile;
  HistoryData? _historyData;
  DashboardModel? _dashboardData; // Add dashboardData to store API response
  bool _isLoading = true;
  bool _forceProfileImageRefresh = false;

  // Computed properties for statistics
  int get _totalDelivered => _historyData?.deliveredPackages ?? 0;
  int get _totalReturned => _historyData?.returnedPackages ?? 0;
  int get _totalPackages => _historyData?.totalDeliveries ?? 0;

  // Convert the list of dashboard orders to a list of packages for Return feature
  List<Package> get _todaysPackages {
    if (_dashboardData == null || _dashboardData!.recentOrders.isEmpty) {
      return [];
    }

    return _dashboardData!.recentOrders
        .map((order) => order.toPackage())
        .toList();
  }

  // List to store history packages from API
  List<Package> _deliveryHistory = [];

  // Variables for lazy loading
  // Add new state variables for search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Package> _filteredPackages = [];

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isDateFilterActive = false;
  String _dateFilterText = 'Semua';

  // Initialize OcrService
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchHistoryData();
    _initializeFilteredPackages();

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Add listener for search changes
    _searchController.addListener(_onSearchChanged);
  }

  // Method to fetch history data from API
  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load both user profile and history data
      final futures = await Future.wait([
        _historyService.getHistoryData(),
        _profileService.getUserProfile(),
        _dashboardService.getDashboardData() // Add dashboard data fetch
      ]);

      // Convert history items to Package objects for UI
      final historyData = futures[0] as HistoryData;
      final packages =
          historyData.history.map((item) => item.toPackage()).toList();

      setState(() {
        _historyData = historyData;
        _userProfile = futures[1] as UserProfile;
        _dashboardData = futures[2] as DashboardModel; // Store dashboard data
        _deliveryHistory = packages;
        _filteredPackages = List.from(packages); // Initialize filtered packages
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message to user
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

      print('Data loading error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
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

  void _initializeFilteredPackages() {
    // Initialize with all packages
    _filteredPackages = List.from(_deliveryHistory);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Start with the full list
    List<Package> filtered = List.from(
        _deliveryHistory); // Apply search filter if query is not empty
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((package) {
        final searchLower = _searchQuery.toLowerCase();
        return package.id.toLowerCase().contains(searchLower) ||
            (package.recipient.isEmpty ? "-" : package.recipient)
                .toLowerCase()
                .contains(searchLower) ||
            (package.address.isEmpty ? "-" : package.address)
                .toLowerCase()
                .contains(searchLower) ||
            (package.items.isEmpty ? "-" : package.items)
                .toLowerCase()
                .contains(searchLower);
      }).toList();
    }

    // Apply status filter if not "Semua"
    if (_selectedFilter != 'Semua') {
      filtered = filtered.where((package) {
        switch (_selectedFilter) {
          case 'Check-out':
            return package.status == PackageStatus.checkout;
          case 'Return':
            return package.status == PackageStatus.returned;
          default:
            return true;
        }
      }).toList();
    }

    // Apply date filter if active
    if (_isDateFilterActive) {
      filtered = filtered.where((package) {
        final packageDate = DateTime(
          package.scheduledDelivery.year,
          package.scheduledDelivery.month,
          package.scheduledDelivery.day,
        );
        final startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
        );
        final endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
        );
        return packageDate.isAtSameMomentAs(startDate) ||
            packageDate.isAtSameMomentAs(endDate) ||
            (packageDate.isAfter(startDate) && packageDate.isBefore(endDate));
      }).toList();
    }

    setState(() {
      _filteredPackages = filtered;
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      if (index == 0) {
        // Navigate back to HomeScreen
        Navigator.pop(context);
      } else if (index == 1) {
        // This is the center button, which should open the scan options
        _showScanOptions();
      }
    }
  }

  void _navigateToProfileScreen() async {
    // Navigate to profile screen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );

    // If profile was updated (result is true), refresh the data
    if (result == true) {
      // Clear image cache for profile picture
      if (_userProfile?.profilePictureUrl != null) {
        await ImageCacheHelper.clearImageCache(
            _userProfile!.profilePictureUrl!);
      }
      // Set flag to force refresh profile image on next build
      setState(() {
        _forceProfileImageRefresh = true;
      });
      _fetchHistoryData(); // Refresh profile data
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _showDatePicker() async {
    // Show date range picker
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isDateFilterActive = true;
        _updateDateFilterText();
        _applyFilters();
      });
    }
  }

  void _updateDateFilterText() {
    if (!_isDateFilterActive) {
      _dateFilterText = 'Semua';
      return;
    }

    final startDay = _startDate.day.toString().padLeft(2, '0');
    final startMonth = _getIndonesianMonth(_startDate.month);
    final endDay = _endDate.day.toString().padLeft(2, '0');
    final endMonth = _getIndonesianMonth(_endDate.month);

    if (_startDate.year == _endDate.year) {
      if (_startDate.month == _endDate.month) {
        if (_startDate.day == _endDate.day) {
          _dateFilterText = '$startDay $startMonth ${_startDate.year}';
        } else {
          _dateFilterText = '$startDay-$endDay $startMonth ${_startDate.year}';
        }
      } else {
        _dateFilterText =
            '$startDay $startMonth - $endDay $endMonth ${_startDate.year}';
      }
    } else {
      _dateFilterText =
          '$startDay $startMonth ${_startDate.year} - $endDay $endMonth ${_endDate.year}';
    }
  }

  void _showPackageDetails(Package package) {
    // Show package details in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPackageDetailsSheet(package),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            // Refresh data ketika user pull-to-refresh
            await _fetchHistoryData();
            // Setelah data diperbarui, reset tampilan packages
            _resetDisplayedPackages();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Mengubah padding bottom agar content bisa scroll sampai bawah melewati bottom navigation
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildSearchAndDateFilter(),
                const SizedBox(height: 24),
                _buildDeliveryStatistics(),
                const SizedBox(height: 24),
                _buildFilterChips(),
                const SizedBox(height: 16),
                _buildPackageHistoryList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      extendBody: true, // Memastikan body extend di bawah bottom navigation
      body: Stack(
        children: [
          _buildBackgroundDecorations(size),
          SafeArea(
            bottom: false, // Memastikan content bisa scroll sampai bawah
            child: _isLoading
                ? _buildSkeletonScreen()
                : Column(
                    children: [
                      _buildHeader(context),
                      Expanded(child: _buildMainContent(context)),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
              color: AppColors.primary.withOpacity(0.08),
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
              color: AppColors.primary.withOpacity(0.06),
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
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and back button
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Image.asset(
                        'assets/images/lokatrack_logo_small.png',
                        fit: BoxFit.contain,
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LokaTrack',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Riwayat Pengiriman',
                      style: TextStyle(
                        color: Colors.black87.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Profile button
            GestureDetector(
              onTap: _navigateToProfileScreen,
              child: _buildProfileImage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      );
    }

    final shouldForceCacheBust = _forceProfileImageRefresh;

    // Reset the flag after using it
    if (_forceProfileImageRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _forceProfileImageRefresh = false;
        });
      });
    }

    return ImageCacheHelper.buildProfileImage(
      imageUrl: _userProfile?.profilePictureUrl,
      radius: 22,
      forceCacheBust: shouldForceCacheBust, // Only force cache bust when needed
      errorWidget: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 27, 94, 32),
            width: 2.5,
          ),
        ),
        child: const CircleAvatar(
          radius: 20,
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          child: Icon(
            Icons.person,
            color: Color.fromARGB(255, 27, 94, 32),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Search box
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari paket...',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date filter
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        _isDateFilterActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color:
                        _isDateFilterActive ? Colors.white : AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isDateFilterActive) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _dateFilterText,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDateFilterActive = false;
                              _dateFilterText = 'Semua';
                              _applyFilters();
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.primary,
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
      ],
    );
  }

  Widget _buildDeliveryStatistics() {
    return SizedBox(
      height: 160,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Delivered statistic
          _buildStatCard(
            title: 'Total Check-out',
            value: _totalDelivered.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            gradientColors: const [Color(0xFF2ECC71), Color(0xFF27AE60)],
          ),

          // Returned statistic
          _buildStatCard(
            title: 'Total Return',
            value: _totalReturned.toString(),
            icon: Icons.assignment_return_outlined,
            color: const Color(0xFFE67E22),
            gradientColors: const [Color(0xFFE67E22), Color(0xFFF39C12)],
          ),

          // Total Packages statistic
          _buildStatCard(
            title: 'Total Pengiriman',
            value: _totalPackages.toString(),
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF9B59B6),
            gradientColors: const [Color(0xFF9B59B6), Color(0xFF8E44AD)],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    bool showStar = false,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon (decorative)
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.1)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showStar)
                      const Padding(
                        padding: EdgeInsets.only(left: 4, top: 5),
                        child: Icon(Icons.star, color: Colors.white, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Pengiriman',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CustomFilterChip(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    onSelected: () => _onFilterSelected(filter),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageHistoryList() {
    // Use filtered packages instead of _deliveryHistory directly
    List<Package> packagesToShow = _filteredPackages;

    if (packagesToShow.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              Icon(
                Icons.history_outlined,
                size: 60,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada riwayat pengiriman $_selectedFilter',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'Semua';
                    _searchController.clear();
                    _applyFilters();
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reset Filter'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: packagesToShow.length,
      itemBuilder: (context, index) {
        final package = packagesToShow[index];
        return _buildPackageHistoryItem(package);
      },
    );
  }

  Widget _buildPackageHistoryItem(Package package) {
    // Format dates
    final formattedDate = _formatDate(package.scheduledDelivery);
    final statusColor = _getStatusColor(package.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPackageDetails(package),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package ID, date and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(package.status),
                            color: statusColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusChip(package.status),
                  ],
                ),

                const Divider(height: 24),

                // Recipient and address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - recipient info
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipient
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  package.recipient.isEmpty
                                      ? "-"
                                      : package.recipient,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Address
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
                                  package.address.isEmpty
                                      ? "-"
                                      : package.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Vertical divider
                    Container(
                      height: 50,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.grey.withOpacity(0.2),
                    ),

                    // Right side - amount and payment info
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total amount
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.payment_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatCurrency(package.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Payment method
                          Row(
                            children: [
                              const Icon(
                                Icons.scale_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${package.weight} kg',
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
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom section - Detail button and item preview
                Row(
                  children: [
                    // Detail button
                    ElevatedButton(
                      onPressed: () => _showPackageDetails(package),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Detail',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Items preview
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              package.items.isEmpty ? "-" : package.items,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageDetailsSheet(Package package) {
    return FutureBuilder<DeliveryDetailData>(
      future: _deliveryDetailService.getDeliveryDetail(package.id),
      builder: (context, snapshot) {
        // Variable to determine if we're in loading state
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;
        // Variable to determine if there's an error
        final bool hasError = snapshot.hasError;

        // Base container for the bottom sheet
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle grip and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Detail Pengiriman',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Package ID and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isLoading
                        ? _buildSkeletonText(width: 120, height: 40)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ID Paket',
                                style:
                                    TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                package.id,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                    isLoading
                        ? _buildSkeletonText(width: 80, height: 30, radius: 8)
                        : _buildStatusChip(package.status),
                  ],
                ),
                const SizedBox(height: 20),

                // Timeline representation - with skeleton loading when data is loading
                isLoading
                    ? _buildSkeletonTimeline()
                    : hasError
                        ? _buildErrorTimeline()
                        : _buildDeliveryTimelineWithAPIData(
                            deliveryStartTime: _parseDateTime(
                                snapshot.data?.deliveryStartTime,
                                package.scheduledDelivery),
                            checkinTime: _parseDateTime(
                                snapshot.data?.checkInTime, null),
                            checkoutTime: _parseDateTime(
                                snapshot.data?.checkOutTime,
                                package.deliveredAt),
                            status: package.status,
                          ),
                const SizedBox(height: 24),

                // Recipient details
                _buildDetailsSection(
                  title: 'Informasi Pembeli',
                  content: [
                    isLoading
                        ? _buildSkeletonDetailRow()
                        : _buildDetailRow(
                            icon: Icons.person_outline,
                            label: 'Nama',
                            value: (snapshot.data?.customer.isEmpty ?? true)
                                ? (package.recipient.isEmpty
                                    ? "-"
                                    : package.recipient)
                                : snapshot.data!.customer,
                          ),
                    isLoading
                        ? _buildSkeletonDetailRow(isLong: true)
                        : _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Alamat',
                            value: (snapshot.data?.address.isEmpty ?? true)
                                ? (package.address.isEmpty
                                    ? "-"
                                    : package.address)
                                : snapshot.data!.address,
                          ),
                    if (!isLoading &&
                        (((snapshot.data?.orderNotes?.isEmpty ?? true)
                                ? package.notes
                                : snapshot.data!.orderNotes!)
                            .isNotEmpty))
                      _buildDetailRow(
                        icon: Icons.note_outlined,
                        label: 'Catatan',
                        value: (snapshot.data?.orderNotes?.isEmpty ?? true)
                            ? (package.notes.isEmpty ? "-" : package.notes)
                            : snapshot.data!.orderNotes!,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Package details - with skeleton loading
                _buildDetailsSection(
                  title: 'Informasi Paket',
                  content: [
                    isLoading
                        ? _buildSkeletonDetailRow()
                        : _buildDetailRow(
                            icon: Icons.inventory_2_outlined,
                            label: 'Item',
                            value: (snapshot.data?.itemsList.isEmpty ?? true)
                                ? (package.items.isEmpty ? "-" : package.items)
                                : snapshot.data!.itemsList,
                          ),
                    isLoading
                        ? _buildSkeletonDetailRow()
                        : _buildDetailRow(
                            icon: Icons.payment_outlined,
                            label: 'Total',
                            value: _formatCurrency((snapshot.data?.totalPrice ??
                                    package.totalAmount.toDouble())
                                .toInt()),
                          ),
                    isLoading
                        ? _buildSkeletonDetailRow()
                        : _buildDetailRow(
                            icon: Icons.scale_outlined,
                            label: 'Total Berat',
                            value:
                                '${(snapshot.data?.totalWeight ?? package.weight).toString()} kg',
                          ),
                    isLoading
                        ? _buildSkeletonDetailRow()
                        : _buildDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Waktu Pengiriman',
                            value: _getFormattedDeliveryDate(
                                snapshot.data?.deliveryStartTime,
                                package.scheduledDelivery),
                          ),
                    if (!isLoading && package.status == PackageStatus.checkin)
                      _buildDetailRow(
                        icon: Icons.login_outlined,
                        label: 'Waktu Check-in',
                        value: _getFormattedCheckInDate(
                            snapshot.data?.checkInTime),
                      ),
                    if (!isLoading && package.status == PackageStatus.checkout)
                      _buildDetailRow(
                        icon: Icons.check_circle_outline,
                        label: 'Waktu Check-out',
                        value: _getFormattedCheckOutDate(
                            snapshot.data?.checkOutTime, package.deliveredAt),
                      ),
                    if (!isLoading &&
                        package.status == PackageStatus.returned &&
                        package.returningReason != null)
                      _buildDetailRow(
                        icon: Icons.info_outline,
                        label: 'Alasan Return',
                        value: package.returningReason!,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // Action based on package status
                                if (package.status == PackageStatus.checkout) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => package.status ==
                                              PackageStatus.returned
                                          ? ReturnDetailScreen(
                                              package: package,
                                            ) // Navigate to Return detail for returned packages
                                          : PackageDetailScreen(
                                              package: package,
                                            ), // Navigate to regular detail for other packages
                                    ),
                                  );
                                } else if (package.status ==
                                    PackageStatus.returned) {
                                  // View return details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReturnDetailScreen(
                                        package: package,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Track package
                                  debugPrint('Track package');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                        ),
                        child: Text(
                          isLoading
                              ? 'Memuat...'
                              : package.status == PackageStatus.checkout
                                  ? 'Detail Paket'
                                  : package.status == PackageStatus.returned
                                      ? 'Detail Return'
                                      : 'Lacak Paket',
                        ),
                      ),
                    ),
                  ],
                ),

                // Error message if needed
                if (hasError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gagal memuat detail. Silakan tutup dan coba lagi.',
                            style:
                                TextStyle(color: Colors.red[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods for date parsing and formatting
  DateTime? _parseDateTime(String? dateTimeString, DateTime? fallback) {
    if (dateTimeString == null) return fallback;
    // Use timezone-aware helper instead of DateTime.parse
    return DateTimeHelper.parseLocalDateTime(dateTimeString) ?? fallback;
  }

  String _getFormattedDeliveryDate(
      String? deliveryStartTime, DateTime fallback) {
    DateTime? date = _parseDateTime(deliveryStartTime, fallback);
    return date != null
        ? DateTimeHelper.formatDateTime(date)
        : "Tidak ada data";
  }

  String _getFormattedCheckInDate(String? checkInTime) {
    DateTime? date = _parseDateTime(checkInTime, null);
    return date != null
        ? DateTimeHelper.formatDateTime(date)
        : "Belum check-in";
  }

  String _getFormattedCheckOutDate(String? checkOutTime, DateTime? fallback) {
    DateTime? date = _parseDateTime(checkOutTime, fallback);
    return date != null
        ? DateTimeHelper.formatDateTime(date)
        : "Belum terkirim";
  }

  // Skeleton widgets for loading state
  Widget _buildSkeletonText(
      {required double width, required double height, double radius = 4}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildSkeletonTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            _buildSkeletonTimelineStep(isFirst: true),
            _buildSkeletonTimelineStep(),
            _buildSkeletonTimelineStep(),
            _buildSkeletonTimelineStep(isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTimelineStep(
      {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: Colors.white,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Step info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(
                width: 120,
                height: 12,
                color: Colors.white,
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonDetailRow({bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: isLong ? double.infinity : 150,
                    height: 14,
                    color: Colors.white,
                  ),
                  if (isLong) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 14,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal memuat data timeline pengiriman',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimelineWithAPIData({
    required DateTime? deliveryStartTime,
    required DateTime? checkinTime,
    required DateTime? checkoutTime,
    required PackageStatus status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            title: 'Order Date',
            time: deliveryStartTime != null
                ? _formatDate(
                    deliveryStartTime.subtract(const Duration(hours: 2)))
                : 'Tidak ada data',
            isCompleted: true,
            isFirst: true,
          ),
          _buildTimelineStep(
            title: 'On Delivery',
            time: deliveryStartTime != null
                ? _formatDate(deliveryStartTime)
                : 'Tidak ada data',
            isCompleted: true,
          ),
          _buildTimelineStep(
            title: 'Check-in',
            time: checkinTime != null
                ? _formatDate(checkinTime)
                : 'Belum check-in',
            isCompleted: checkinTime != null,
          ),
          _buildTimelineStep(
            title: status == PackageStatus.returned ? 'Returned' : 'Check-out',
            time: status == PackageStatus.checkout && checkoutTime != null
                ? _formatDate(checkoutTime)
                : status == PackageStatus.returned
                    ? checkinTime != null
                        ? _formatDate(checkinTime.add(const Duration(hours: 3)))
                        : 'Tidak ada data'
                    : 'In Progress',
            isCompleted: status == PackageStatus.checkout ||
                status == PackageStatus.returned,
            isLast: true,
            isHighlighted: status == PackageStatus.checkout,
            isError: status == PackageStatus.returned,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
    bool isHighlighted = false,
    bool isError = false,
  }) {
    Color stepColor = isHighlighted
        ? const Color(0xFF2ECC71)
        : isError
            ? const Color(0xFFE74C3C)
            : isCompleted
                ? AppColors.primary
                : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? stepColor : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? stepColor : Colors.grey.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      isError ? Icons.close : Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? stepColor : Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Step info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? stepColor : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: content),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(PackageStatus status) {
    switch (status) {
      case PackageStatus.onDelivery:
        return Icons.local_shipping_outlined;
      case PackageStatus.checkin:
        return Icons.login_outlined;
      case PackageStatus.checkout:
        return Icons.check_circle_outline;
      case PackageStatus.returned:
        return Icons.assignment_return_outlined;
    }
  }

  Color _getStatusColor(PackageStatus status) {
    switch (status) {
      case PackageStatus.onDelivery:
        return const Color(0xFF3498DB);
      case PackageStatus.checkin:
        return const Color(0xFFE67E22);
      case PackageStatus.checkout:
        return const Color(0xFF2ECC71);
      case PackageStatus.returned:
        return const Color(0xFFE74C3C);
    }
  }

  String _formatDate(DateTime date) {
    // Format the date in Indonesian locale
    final day = date.day.toString().padLeft(2, '0');
    final month = _getIndonesianMonth(date.month);
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  String _getIndonesianMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  String _formatCurrency(int amount) {
    // Format as Indonesian Rupiah
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedAmount = amount.toString().replaceAllMapped(
          formatter,
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formattedAmount';
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pilih Jenis Scan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF306424),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Silakan pilih tipe scan yang akan dilakukan',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Add New Delivery
              _buildScanOptionButton(
                icon: Icons.add_box_outlined,
                title: 'Tambah Pengiriman Baru',
                description: 'Scan dokumen untuk pengiriman baru',
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _openCamera(isNewDelivery: true);
                },
              ),

              const SizedBox(height: 16),

              // Return Package Option
              _buildScanOptionButton(
                icon: Icons.assignment_return_outlined,
                title: 'Return Paket Pengiriman',
                description: 'Scan dokumen untuk return paket',
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _showReturnPackageSelection();
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // Method to build scan option button for bottom sheet
  Widget _buildScanOptionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF306424).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF306424).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF306424),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF306424),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method to show check-in packages for return selection
  void _showReturnPackageSelection() {
    // Filter packages with Check-in status
    final List<Package> checkInPackages = _todaysPackages
        .where((package) => package.status == PackageStatus.checkin)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle grip
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              const Text(
                'Return Paket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF306424),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                checkInPackages.isEmpty
                    ? 'Tidak ada paket dengan status Check-in yang tersedia untuk return'
                    : 'Pilih paket yang akan direturn:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // No packages message or package list
              checkInPackages.isEmpty
                  ? _buildNoCheckInPackages()
                  : Expanded(
                      child: ListView.builder(
                        itemCount: checkInPackages.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return _buildReturnPackageCard(
                              checkInPackages[index]);
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // Widget for when no check-in packages are available for return
  Widget _buildNoCheckInPackages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_return_outlined,
              size: 40,
              color: const Color(0xFF306424).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada paket untuk direturn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF306424),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda harus melakukan check-in paket terlebih dahulu sebelum dapat melakukan return',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCheckInPackageSelection(); // Show On Delivery packages for check-in
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF306424),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Check-in Paket'),
          ),
        ],
      ),
    );
  }

  // New method to show on-delivery packages for check-in selection - modified to use today's packages
  void _showCheckInPackageSelection() {
    // Filter packages with On Delivery status from today's packages instead of history
    final List<Package> onDeliveryPackages = _todaysPackages
        .where((package) => package.status == PackageStatus.onDelivery)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle grip
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              const Text(
                'Check-in Paket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF306424),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                onDeliveryPackages.isEmpty
                    ? 'Tidak ada paket dengan status On Delivery yang tersedia untuk check-in'
                    : 'Pilih paket yang akan di-check-in:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // No packages message or package list
              onDeliveryPackages.isEmpty
                  ? _buildNoOnDeliveryPackages()
                  : Expanded(
                      child: ListView.builder(
                        itemCount: onDeliveryPackages.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return _buildCheckInPackageCard(
                              onDeliveryPackages[index]);
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // Widget for when no on-delivery packages are available for check-in
  Widget _buildNoOnDeliveryPackages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 40,
              color: const Color(0xFF306424).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada paket untuk di-check-in',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF306424),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada paket dengan status On Delivery. Anda harus menambahkan paket baru terlebih dahulu.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openCamera(isNewDelivery: true); // Navigate to add new package
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF306424),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Tambah Paket Baru'),
          ),
        ],
      ),
    );
  }

  // Card for package to be checked in
  Widget _buildCheckInPackageCard(Package package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF306424).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close bottom sheet

            // Navigate to package update screen instead of update status confirmation
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdatePackageScreen(package: package),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Package icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFF3498DB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Package details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF306424),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.recipient,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.items,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF306424),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card for package to be returned
  Widget _buildReturnPackageCard(Package package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF306424).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close bottom sheet
            _openReturnCamera(package);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Package icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_return_outlined,
                    color: Color(0xFFE67E22),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Package details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF306424),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.recipient,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.items,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF306424),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to open camera for return package
  Future<void> _openReturnCamera(Package package) async {
    try {
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

      // Initialize the ImagePicker
      final ImagePicker picker = ImagePicker();

      // Capture image from camera
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (photo != null) {
        // Create list of captured images
        List<File> capturedImages = [File(photo.path)];

        // Navigate to DocumentConfirmationScreen first, which will then go to ReturnConfirmationScreen
        // This makes the flow same as home screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentConfirmationScreen(
                deliveryId: package.id,
                capturedImages: capturedImages,
                package: package,
                returnReason: "Pelanggan tidak ada di tempat", // Default reason
                notes: "", // Empty notes initially
              ),
            ),
          );
        }
      } else {
        // User cancelled the camera
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pengambilan gambar dibatalkan"),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
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

  Future<void> _openCamera({required bool isNewDelivery}) async {
    try {
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

      // Initialize the ImagePicker
      final ImagePicker picker = ImagePicker();

      // Capture image from camera
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (photo != null) {
        // Show processing dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF306424),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Memproses dokumen..."),
                ],
              ),
            );
          },
        );

        // Process the image with our modified dummy OCR function
        await _processImageWithOCR(
          imagePath: photo.path,
          isNewDelivery: isNewDelivery,
        );

        // Note: The processing dialog will be closed by the _processImageWithOCR function
      } else {
        // User cancelled the camera
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengambilan gambar dibatalkan"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      // Handle any errors
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

  Future<void> _processImageWithOCR({
    required String imagePath,
    required bool isNewDelivery,
  }) async {
    try {
      // Process the image with OCR API
      final File imageFile = File(imagePath);

      // Call the OCR API through OcrService
      final ocrResponse = await _ocrService.getOrderNumberFromImage(imageFile);

      // Close processing dialog
      if (context.mounted) Navigator.pop(context);

      // Get the extracted order number from API response
      // Menambahkan null-safety dengan menggunakan nilai default jika null
      final String extractedOrderNumber =
          ocrResponse.data.orderNo ?? "PKT-UNKNOWN";

      // Optional: Show a brief success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Berhasil mengekstrak ID Paket: $extractedOrderNumber"),
            backgroundColor: const Color(0xFF306424),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Navigate to appropriate screen based on scan type
      if (isNewDelivery && context.mounted) {
        // Navigate to new delivery confirmation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPackageConfirmationScreen(
              imagePath: imagePath,
              detectedPackageId: extractedOrderNumber,
            ),
          ),
        );
      } else if (context.mounted) {
        // For future implementation: Status update flow
        await Future.delayed(const Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update status untuk paket: $extractedOrderNumber"),
            backgroundColor: const Color(0xFF306424),
          ),
        );
      }
    } catch (e) {
      // Handle exceptions
      if (context.mounted) {
        Navigator.pop(context); // Make sure dialog is closed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Navigation Bar with improved shadow and corners
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home Button - Left Side
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Beranda',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                ),

                // Center Empty Space for FAB
                const Expanded(child: SizedBox()),

                // History Button - Right Side
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history_rounded,
                    label: 'Riwayat',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                ),
              ],
            ),
          ),

          // Centered OCR Button - Improved for visibility
          Positioned(
            top: 8,
            child: Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4C8C3D), Color(0xFF306424)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF306424).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias, // Ensures ink stays within bounds
                child: InkWell(
                  onTap: _showScanOptions,
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.document_scanner_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Scan OCR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF306424).withOpacity(0.1),
        highlightColor: const Color(0xFF306424).withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color:
                    isSelected ? const Color(0xFF306424) : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF306424)
                      : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New skeleton screen widget
  Widget _buildSkeletonScreen() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          // Skeleton header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo and back button skeleton
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 120,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                // Profile skeleton
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Main content skeleton
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Search bar skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics cards skeleton
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filter chips skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 160,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(
                            3,
                            (index) => Container(
                              width: 80,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Package list skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 160,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      },
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

  // Reset the displayed packages (simplified - no longer using pagination)
  void _resetDisplayedPackages() {
    // This method is called after refresh to ensure the UI updates
    // No additional state management needed since _filteredPackages is used directly
  }
}
