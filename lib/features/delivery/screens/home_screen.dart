import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/package.dart';
import '../screens/history_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'all_delivery_screen.dart';
import '../screens/add_package_confirmation.dart';
import 'qr_detector_screen.dart';
import 'package_detail.dart';
import 'package_update.dart';
import 'return_detail.dart';
import 'document_confirmation_screen.dart';
import '../../../utils/greeting_helper.dart';
import '../../../features/profile/services/profile_service.dart';
import '../../../features/profile/models/user_profile_model.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import '../services/ocr_service.dart';
import '../models/ocr_response_model.dart';
import '../../../utils/image_cache_helper.dart';
import 'tips_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ProfileService _profileService = ProfileService();
  final DashboardService _dashboardService = DashboardService();
  UserProfile? _userProfile;
  DashboardModel? _dashboardData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _forceProfileImageRefresh = false;

  // Tips section variables
  late PageController _tipsPageController;
  late Timer _tipsTimer;
  int _currentTipIndex = 0;

  // Delivery tips data
  final List<Map<String, dynamic>> _deliveryTips = [
    {
      'title': 'Periksa Kondisi Sayuran',
      'description':
          'Pastikan semua sayuran dalam kondisi segar dan tidak ada yang rusak sebelum dikirim',
      'icon': Icons.eco_outlined,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'Kemasan yang Aman',
      'description':
          'Gunakan kemasan yang tepat untuk menjaga kualitas sayuran selama perjalanan',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFF2196F3),
    },
    {
      'title': 'Waktu Pengiriman',
      'description':
          'Kirim sayuran pada waktu yang tepat untuk menjaga kesegaran produk',
      'icon': Icons.schedule_outlined,
      'color': const Color(0xFFFF9800),
    },
    {
      'title': 'Suhu yang Tepat',
      'description':
          'Jaga suhu penyimpanan yang sesuai untuk masing-masing jenis sayuran',
      'icon': Icons.thermostat_outlined,
      'color': const Color(0xFF9C27B0),
    },
    {
      'title': 'Komunikasi Pelanggan',
      'description':
          'Informasikan status pengiriman kepada pelanggan secara berkala',
      'icon': Icons.message_outlined,
      'color': const Color(0xFFE91E63),
    },
    {
      'title': 'Handling yang Hati-hati',
      'description':
          'Tangani sayuran dengan hati-hati untuk menghindari kerusakan fisik',
      'icon': Icons.pan_tool_outlined,
      'color': const Color(0xFF795548),
    },
  ];

  // Helper methods for safe data handling
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

  // Convert the list of recent orders to a list of packages for UI display with sorting
  List<Package> get _packagesToDeliver {
    if (_dashboardData == null || _dashboardData!.recentOrders.isEmpty) {
      return [];
    }

    final packages =
        _dashboardData!.recentOrders.map((order) => order.toPackage()).toList();

    // Sort packages by status priority: check-in > on-delivery > checkout/return
    packages.sort((a, b) {
      int getPriority(PackageStatus status) {
        switch (status) {
          case PackageStatus.checkin:
            return 1; // Highest priority
          case PackageStatus.onDelivery:
            return 2;
          case PackageStatus.checkout:
            return 3;
          case PackageStatus.returned:
            return 4; // Lowest priority
        }
      }

      return getPriority(a.status).compareTo(getPriority(b.status));
    });

    return packages;
  }

  // Computed properties for stat cards with safe data handling
  int get _totalDelivered => _safeInt(_dashboardData?.deliveredPackages, 0);
  int get _totalReturned => _safeInt(_dashboardData?.returnedPackages, 0);

  // Fixed percentage calculation - verify if this comes from API or needs calculation
  double get _completionRate {
    final percentage = _safeDouble(_dashboardData?.percentage, 0.0);

    // If API provides percentage directly, use it
    if (percentage > 0) {
      return percentage;
    }

    // Otherwise calculate success rate: delivered / (delivered + returned) * 100
    final delivered = _totalDelivered;
    final returned = _totalReturned;
    final total = delivered + returned;

    if (total > 0) {
      return (delivered / total) * 100;
    }

    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
    _setupTipsSlider();

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Combined method to load both user profile and dashboard data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load both user profile and dashboard data in parallel
      final results = await Future.wait([
        _profileService.getUserProfile(),
        _dashboardService.getDashboardData(),
      ]);

      setState(() {
        _userProfile = results[0] as UserProfile;
        _dashboardData = results[1] as DashboardModel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });

      // Display error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      print('Data loading error: $e');
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

  void _setupTipsSlider() {
    _tipsPageController = PageController();

    // Setup auto-slider timer
    _tipsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentTipIndex < _deliveryTips.length - 1) {
        _currentTipIndex++;
      } else {
        _currentTipIndex = 0;
      }

      if (_tipsPageController.hasClients) {
        _tipsPageController.animateToPage(
          _currentTipIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onTipPageChanged(int index) {
    setState(() {
      _currentTipIndex = index;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tipsTimer.cancel();
    _tipsPageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      // Handle navigation based on bottom navigation bar selection
      if (index == 0) {
        // Home screen, already there
      } else if (index == 2) {
        // Navigate to History screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoryScreen()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
      }
    }
  }

  void _navigateToProfile() async {
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
      _loadData(); // Refresh profile data
    }
  }

  void _navigateToScanScreen() {
    // Open QR detector for new package scan
    _openQrDetector();
  }

  void _openQrDetector() {
    // Navigate to QR detector screen for new packages only
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrDetectorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Show skeleton loading screen while fetching user profile data
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF5),
        body: Stack(
          children: [
            // Background decorations for skeleton view
            _buildBackgroundDecorations(size),

            // Skeleton loading UI
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header skeleton
                  _buildHeaderSkeleton(),

                  // Main content skeleton - scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Welcome message skeleton
                          _buildWelcomeMessageSkeleton(),

                          const SizedBox(height: 24),

                          // Statistics skeleton
                          _buildStatisticsSkeleton(),

                          const SizedBox(height: 24),

                          // Today's deliveries title skeleton
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSkeletonText(width: 160, height: 22),
                                _buildSkeletonText(width: 80, height: 18),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Package list skeleton
                          _buildPackageListSkeleton(),

                          const SizedBox(height: 16),

                          // Tips section skeleton
                          _buildTipsSkeleton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        extendBody: true,
      );
    }

    // Main UI content - shown only after loading completes
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      body: Stack(
        children: [
          // Background decorations
          _buildBackgroundDecorations(size),

          // Main content
          SafeArea(
            bottom: false, // Important: Don't add safe area to bottom
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Main content - scrollable
                Expanded(child: _buildMainContent(context)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      extendBody: true,
    );
  }

  // Skeleton UI components

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and text skeleton
          Row(
            children: [
              _buildShimmerContainer(
                width: 52,
                height: 52,
                borderRadius: 26,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonText(width: 80, height: 18),
                  const SizedBox(height: 4),
                  _buildSkeletonText(width: 100, height: 12),
                ],
              ),
            ],
          ),

          // Profile picture skeleton
          _buildShimmerContainer(
            width: 44,
            height: 44,
            borderRadius: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessageSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonText(width: 120, height: 14),
          const SizedBox(height: 8),
          _buildSkeletonText(width: 180, height: 24),
        ],
      ),
    );
  }

  Widget _buildStatisticsSkeleton() {
    return SizedBox(
      height: 160,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatCardSkeleton(),
          _buildStatCardSkeleton(),
          _buildStatCardSkeleton(),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerContainer(
              width: 28,
              height: 28,
              borderRadius: 14,
            ),
            const Spacer(),
            _buildSkeletonText(width: 60, height: 32),
            const SizedBox(height: 4),
            _buildSkeletonText(width: 100, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageListSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPackageItemSkeleton(),
          const SizedBox(height: 12),
          _buildPackageItemSkeleton(),
          const SizedBox(height: 12),
          _buildPackageItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildPackageItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package ID and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonText(width: 100, height: 16),
              _buildShimmerContainer(
                width: 80,
                height: 24,
                borderRadius: 12,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recipient name
          Row(
            children: [
              _buildShimmerContainer(
                width: 16,
                height: 16,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              _buildSkeletonText(width: 150, height: 14),
            ],
          ),

          const SizedBox(height: 8),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerContainer(
                width: 16,
                height: 16,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSkeletonText(width: double.infinity, height: 13),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerContainer(
                width: 16,
                height: 16,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSkeletonText(width: double.infinity, height: 13),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom row with delivery time and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonText(width: 120, height: 12),
              Row(
                children: [
                  _buildShimmerContainer(
                    width: 80,
                    height: 36,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerContainer(
                    width: 80,
                    height: 36,
                    borderRadius: 8,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildShimmerContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 16,
      ),
    );
  }

  // Helper methods for skeleton UI

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
      ),
      // Apply shimmer effect using an animated container
      child: ShimmerEffect(),
    );
  }

  Widget _buildSkeletonText({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
      ),
      // Apply shimmer effect
      child: ShimmerEffect(),
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
              color: const Color(0xFF306424).withValues(alpha: 0.08),
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
              color: const Color(0xFF306424).withValues(alpha: 0.06),
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
              color: const Color(0xFF306424).withValues(alpha: 0.2),
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
            // Logo
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF306424).withValues(alpha: 0.12),
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
                        color: Color(0xFF306424),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Driver Delivery',
                      style: TextStyle(
                        color: Colors.black87.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Profile button
            GestureDetector(
              onTap: _navigateToProfile,
              child: _buildProfileImage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
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

  Widget _buildMainContent(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          color: const Color(0xFF306424),
          onRefresh: () async {
            // Refresh user profile data
            await _loadData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                    height:
                        8), // Welcome message - Updated to use safe data handling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${GreetingHelper.getGreeting()},',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _safeString(_userProfile?.username, 'Pengguna'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Delivery statistics summary
                _buildDeliveryStatistics(),

                const SizedBox(height: 24),

                // Today's deliveries
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pengiriman Hari Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DeliveryListScreen(),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Package list
                _buildPackageList(),

                const SizedBox(height: 16),

                // Tips section
                _buildTipsSection(),
              ],
            ),
          ),
        ),
      ),
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
            title: 'Paket Terkirim',
            value: _safeInt(_totalDelivered, 0).toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF306424),
            gradientColors: const [Color(0xFF306424), Color(0xFF4C8C3D)],
          ),

          // Returned statistic
          _buildStatCard(
            title: 'Paket Return',
            value: _safeInt(_totalReturned, 0).toString(),
            icon: Icons.assignment_return_outlined,
            color: const Color(0xFFE67E22),
            gradientColors: const [Color(0xFFE67E22), Color(0xFFF39C12)],
          ),

          // Completion rate with fixed calculation
          _buildStatCard(
            title: 'Tingkat Keberhasilan',
            value: '${_completionRate.toStringAsFixed(1)}%',
            icon: Icons.insights_outlined,
            color: const Color(0xFF3498DB),
            gradientColors: const [Color(0xFF3498DB), Color(0xFF2980B9)],
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
  }) {
    return Container(
      width: 160,
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
            color: color.withValues(alpha: 0.3),
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
            child: Icon(icon,
                size: 100, color: Colors.white.withValues(alpha: 0.1)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList() {
    if (_packagesToDeliver.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada paket untuk dikirim hari ini',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToScanScreen,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF306424),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Tambah Paket Baru'),
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
      itemCount: _packagesToDeliver.length,
      itemBuilder: (context, index) {
        final package = _packagesToDeliver[index];
        return _buildPackageItem(package);
      },
    );
  }

  Widget _buildPackageItem(Package package) {
    // Format delivery time
    final hour = package.scheduledDelivery.hour.toString().padLeft(2, '0');
    final minute = package.scheduledDelivery.minute.toString().padLeft(2, '0');
    final deliveryTime = "$hour:$minute";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          onTap: () {
            // Navigate to package detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => package.status == PackageStatus.returned
                    ? ReturnDetailScreen(
                        package: package,
                      ) // Navigate to Return detail for returned packages
                    : PackageDetailScreen(
                        package: package,
                      ), // Navigate to regular detail for other packages
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package ID and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      package.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF306424),
                      ),
                    ),
                    _buildStatusChip(package.status),
                  ],
                ),

                const SizedBox(height: 12), // Recipient name
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _safeString(package.recipient, 'No Recipient'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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
                        _safeString(package.address, '-'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Items
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
                        _safeString(package.items, 'No Items'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom row with delivery time and action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Delivery time
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dikirim: $deliveryTime WIB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Action buttons row
                    Row(
                      children: [
                        // Update button with icon - only show for onDelivery status
                        if (package.status == PackageStatus.onDelivery ||
                            package.status == PackageStatus.checkin)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdatePackageScreen(package: package),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF306424)
                                        .withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 68, minHeight: 36),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.update,
                                        size: 16,
                                        color: Color(0xFF306424),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Update',
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
                            ),
                          ),

                        // Add spacing only when Update button is shown
                        if (package.status == PackageStatus.onDelivery ||
                            package.status == PackageStatus.checkin)
                          const SizedBox(width: 8),

                        // Detail button with icon
                        ElevatedButton.icon(
                          onPressed: () {
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
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF306424),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(68, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Detail'),
                        ),
                      ],
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

  Widget _buildStatusChip(PackageStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case PackageStatus.onDelivery:
        bgColor = const Color(0xFF3498DB).withValues(alpha: 0.15);
        textColor = const Color(0xFF2980B9);
        text = 'On Delivery';
        break;
      case PackageStatus.checkin:
        bgColor = const Color(0xFFE67E22).withValues(alpha: 0.15);
        textColor = const Color(0xFFD35400);
        text = 'Check-in';
        break;
      case PackageStatus.checkout:
        bgColor = const Color(0xFF2ECC71).withValues(alpha: 0.15);
        textColor = const Color(0xFF27AE60);
        text = 'Check-out';
        break;
      case PackageStatus.returned:
        bgColor = const Color(0xFFE74C3C).withValues(alpha: 0.15);
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

  Widget _buildTipsSection() {
    return buildTipsSection(
      _tipsPageController,
      _currentTipIndex,
      _deliveryTips,
      _onTipPageChanged,
    );
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
              const SizedBox(height: 32), // Add New Delivery
              _buildScanOptionButton(
                icon: Icons.add_box_outlined,
                title: 'Tambah Pengiriman Baru',
                description: 'Scan QR Code atau dokumen untuk pengiriman baru',
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _openQrDetector();
                },
              ),

              const SizedBox(height: 16),

              // Return Package Option (previously Update Status)
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

  // New method to show check-in packages for return selection
  void _showReturnPackageSelection() {
    // Filter packages with Check-in status
    final List<Package> checkInPackages = _packagesToDeliver
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

  // Widget for when no packages are available for return
  Widget _buildNoCheckInPackages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: const Color(0xFF306424).withValues(alpha: 0.7),
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

  // New method to show on-delivery packages for check-in selection
  void _showCheckInPackageSelection() {
    // Filter packages with On Delivery status
    final List<Package> onDeliveryPackages = _packagesToDeliver
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
              color: const Color(0xFF306424).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 40,
              color: const Color(0xFF306424).withValues(alpha: 0.7),
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
          color: const Color(0xFF306424).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    color: const Color(0xFF3498DB).withValues(alpha: 0.1),
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
                        _safeString(package.id, 'No Package ID'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF306424),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _safeString(package.recipient, 'No Recipient'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _safeString(package.items, 'No Items'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.6),
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
          color: const Color(0xFF306424).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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

            // First open camera to scan delivery order document
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
                    color: const Color(0xFFE67E22).withValues(alpha: 0.1),
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
                        _safeString(package.id, 'No Package ID'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF306424),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _safeString(package.recipient, 'No Recipient'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _safeString(package.items, 'No Items'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  color: Colors.black.withValues(alpha: 0.15),
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
                    color: const Color(0xFF306424).withValues(alpha: 0.3),
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
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.document_scanner_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
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
        splashColor: const Color(0xFF306424).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF306424).withValues(alpha: 0.05),
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
          color: const Color(0xFF306424).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF306424).withValues(alpha: 0.1),
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

  // Method to open camera for new delivery or status update
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
                  Text("Memproses scan barcode..."),
                ],
              ),
            );
          },
        );

        String detectedPackageId = ""; // Default empty ID

        try {
          // Use OCR service to extract order number from barcode image
          final OcrService ocrService = OcrService();
          final BarcodeScanResponse barcodeScanResponse =
              await ocrService.getOrderNumberFromImage(File(photo.path));

          // Extract detected package ID from response
          detectedPackageId = barcodeScanResponse.data.orderNo ?? "";

          debugPrint(
              'Barcode scan successfully detected order number: $detectedPackageId');
          debugPrint(
              'Barcode scan detected URL: ${barcodeScanResponse.data.url ?? "No URL"}');
        } catch (e) {
          debugPrint('Barcode scan processing error: $e');
          // We'll still continue even if barcode scan fails, user can input manually
        }

        // Close processing dialog
        if (context.mounted) Navigator.pop(context);

        // Navigate to appropriate confirmation screen
        if (isNewDelivery) {
          // Navigate to new package confirmation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPackageConfirmationScreen(
                imagePath: photo.path,
                detectedPackageId: detectedPackageId,
              ),
            ),
          );
        }
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
      Navigator.pop(context);

      if (photo != null) {
        // Navigate to document confirmation screen instead of directly showing processing dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentConfirmationScreen(
              deliveryId: package.id,
              capturedImages: [File(photo.path)],
              package: package,
              returnReason: "Barang dikembalikan ke gudang",
              notes: "",
            ),
          ),
        );
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
}

// Shimmer effect widget
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({Key? key}) : super(key: key);

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
                (_animation.value + 1.0).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
