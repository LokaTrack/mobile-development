import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../delivery/widgets/custom_dialog.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/profile_service.dart';
import '../../../utils/image_cache_helper.dart';
import '../../../utils/datetime_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _profileService = ProfileService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic> _userProfile = {};
  bool _isLoading = true;

  // State variables for edit sections
  bool _isEditingUsername = false;
  bool _isEditingPhone = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;

  // Text editing controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  File? _selectedImage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  bool _isUpdatingUsername = false;
  String? _usernameError;

  bool _isUpdatingPhone = false;
  String? _phoneError;
  bool _isUpdatingPassword = false;
  String? _passwordError;

  // Add this flag to track if profile was updated
  bool _profileUpdated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchProfile(); // Fetch profile data when screen loads

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Add method to fetch profile data from API
  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Fetching profile data...');
      final profileData = await _profileService.getProfile();

      if (mounted) {
        setState(() {
          _userProfile = profileData;
          _isLoading = false;
        }); // Update text controllers with fetched data
        _usernameController.text = _userProfile['username'] ?? '';
        _phoneController.text = _userProfile['phoneNumber'] ?? '';
        _emailController.text = _userProfile['email'] ?? '';

        debugPrint('Profile data loaded successfully');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Delay showing error to ensure context is available
        Future.delayed(Duration.zero, () {
          _showErrorSnackBar('Failed to load profile: ${e.toString()}');

          // If token related error, redirect to login
          if (e.toString().contains('token') ||
              e.toString().contains('login') ||
              e.toString().contains('session')) {
            _redirectToLogin();
          }
        });
      }
    }
  }

  // Add method to redirect to login if session expired
  void _redirectToLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CustomDialog(
        title: 'Session Expired',
        content: 'Your session has expired. Please login again.',
        positiveButtonText: 'Login',
        negativeButtonText: '', // Empty string instead of null
        onPositivePressed: () async {
          Navigator.of(context).pop();
          await _authService.logout();

          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        },
        onNegativePressed: () {},
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Format date helper method
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTimeHelper.parseLocalDateTime(dateString);
      if (date == null) return 'Invalid date';
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
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
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomDialog(
        title: 'Konfirmasi Logout',
        content: 'Apakah Anda yakin ingin keluar dari aplikasi?',
        positiveButtonText: 'Ya, Logout',
        negativeButtonText: 'Batal',
        onPositivePressed: () async {
          // Close dialog first
          Navigator.of(context).pop();

          // Show a loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
                ),
              );
            },
          );

          // Perform logout using AuthService
          await _authService.logout();

          if (!mounted) return;

          // Close loading indicator
          Navigator.pop(context);

          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        },
        onNegativePressed: () {
          Navigator.of(context).pop(); // Close dialog
        },
      ),
    );
  }

  // Update profile data methods
  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();

    // Skip update if username hasn't changed
    if (newUsername == _userProfile['username']) {
      setState(() {
        _isEditingUsername = false;
      });
      return;
    }

    if (newUsername.isEmpty) {
      setState(() {
        _usernameError = 'Username tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _isUpdatingUsername = true;
      _usernameError = null;
    });

    try {
      final success = await _profileService.updateUsername(newUsername);

      if (mounted) {
        setState(() {
          _isUpdatingUsername = false;
          _isEditingUsername = false;

          if (success) {
            // Update the local profile data
            _userProfile = {
              ..._userProfile,
              'username': newUsername,
            };
            _profileUpdated = true; // Set flag to indicate profile was updated
          }
        });

        if (success) {
          _showSuccessSnackBar('Username berhasil diperbarui');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingUsername = false;
          _usernameError = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // Update phone number method
  Future<void> _updatePhone() async {
    final newPhoneNumber = _phoneController.text.trim();

    if (newPhoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Nomor telepon tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _isUpdatingPhone = true;
      _phoneError = null;
    });

    try {
      final success = await _profileService.updatePhoneNumber(newPhoneNumber);

      if (mounted) {
        setState(() {
          _isUpdatingPhone = false;
          _isEditingPhone = false;
          if (success) {
            // Update the local profile data
            _userProfile = {
              ..._userProfile,
              'phoneNumber': newPhoneNumber,
            };
            _profileUpdated = true; // Set flag to indicate profile was updated
          }
        });

        if (success) {
          _showSuccessSnackBar('Nomor telepon berhasil diperbarui');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingPhone = false;
          _phoneError = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // Update the password update method to use the API
  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate password fields (redundant check, but good for safety)
    if (currentPassword.isEmpty) {
      setState(() {
        _passwordError = 'Password saat ini tidak boleh kosong';
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        _passwordError = 'Password baru tidak boleh kosong';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _passwordError = 'Konfirmasi password tidak boleh kosong';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordError = 'Password baru dan konfirmasi tidak cocok';
      });
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordError = null;
    });

    try {
      final success = await _profileService.updatePassword(
          currentPassword, newPassword, confirmPassword);

      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;

          if (success) {
            _isEditingPassword = false;
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            _profileUpdated = true; // Set flag to indicate profile was updated
          }
        });

        if (success) {
          _showSuccessSnackBar('Password berhasil diperbarui');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
          _passwordError = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF306424),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Consolidated method to pick an image from camera or gallery
  Future<void> _getImageAndShowPreview(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Show preview dialog
        _showImagePreviewDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Method to show image preview dialog
  void _showImagePreviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Preview Profile Picture'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _uploadProfilePicture,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  } // Method to upload the profile picture

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    Navigator.of(context).pop(); // Close the preview dialog

    try {
      // Clear old image cache before uploading new one
      if (_userProfile.containsKey('profilePictureUrl') &&
          _userProfile['profilePictureUrl'] != null) {
        await ImageCacheHelper.clearImageCache(
            _userProfile['profilePictureUrl'].toString());
      }

      // Call the service to update profile picture
      final newProfilePictureUrl =
          await _profileService.updateProfilePicture(_selectedImage!);

      // Update the profile data in the state with the new URL
      setState(() {
        _userProfile = {
          ..._userProfile, // This is safe now because _userProfile is initialized as empty map
          'profilePictureUrl': newProfilePictureUrl,
        };
        _selectedImage = null;
        _profileImage = null; // Also clear this to avoid conflicts
        _profileUpdated = true; // Set flag to indicate profile was updated
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}')),
      );
    }
  }

  // Consolidated method to show image source options
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _getImageAndShowPreview(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _getImageAndShowPreview(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper methods for profile picture
  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_userProfile.containsKey('profilePictureUrl') &&
        _userProfile['profilePictureUrl'] != null &&
        _userProfile['profilePictureUrl'].toString().isNotEmpty) {
      try {
        // Add cache buster to force image refresh
        final imageUrl = ImageCacheHelper.addCacheBuster(
            _userProfile['profilePictureUrl'].toString());
        return NetworkImage(imageUrl);
      } catch (e) {
        debugPrint('Error loading profile image: $e');
        return null;
      }
    }
    return null;
  }

  bool _shouldShowDefaultIcon() {
    return _selectedImage == null &&
        _profileImage == null &&
        (!_userProfile.containsKey('profilePictureUrl') ||
            _userProfile['profilePictureUrl'] == null ||
            _userProfile['profilePictureUrl'].toString().isEmpty);
  }

  // Add the missing _buildImageSourceOption method
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF306424).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF306424), size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Add this method to your ProfileScreen class to confirm before updating username
  void _confirmUsernameUpdate() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      setState(() {
        _usernameError = 'Username tidak boleh kosong';
      });
      return;
    }

    // Skip confirmation if username hasn't changed
    if (newUsername == _userProfile['username']) {
      setState(() {
        _usernameError = 'Username sama dengan yang tersimpan';
      });
      return;
    }

    // Clear any previous error
    setState(() {
      _usernameError = null;
    });

    ConfirmationDialog.show(
      context: context,
      title: 'Perbarui Username',
      message:
          'Apakah Anda yakin ingin mengubah username menjadi "$newUsername"?',
      onConfirm: _updateUsername,
    );
  }

  // Similarly, add these confirmation methods for other profile updates
  void _confirmPhoneUpdate() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    final newPhoneNumber = _phoneController.text.trim();

    if (newPhoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Nomor telepon tidak boleh kosong';
      });
      return;
    }

    // Skip confirmation if phone number hasn't changed
    if (newPhoneNumber == _userProfile['phoneNumber']) {
      setState(() {
        _phoneError = 'Nomor telepon sama dengan yang tersimpan';
      });
      return;
    }

    // Clear any previous error
    setState(() {
      _phoneError = null;
    });

    ConfirmationDialog.show(
      context: context,
      title: 'Perbarui Nomor Telepon',
      message:
          'Apakah Anda yakin ingin mengubah nomor telepon menjadi "$newPhoneNumber"?',
      onConfirm: _updatePhone,
    );
  }

  void _confirmEmailUpdate() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    final newEmail = _emailController.text.trim();

    if (newEmail.isEmpty) {
      _showErrorSnackBar('Email tidak boleh kosong');
      return;
    }

    // Skip confirmation if email hasn't changed
    if (newEmail == _userProfile['email']) {
      _showErrorSnackBar('Email sama dengan yang tersimpan');
      return;
    }

    ConfirmationDialog.show(
      context: context,
      title: 'Perbarui Email',
      message:
          'Apakah Anda yakin ingin mengubah email menjadi "$newEmail"?\n\nAnda perlu memverifikasi email baru Anda setelah perubahan ini.',
      onConfirm: () {
        // Implement email update API call
        _showSuccessSnackBar('Fitur perbarui email akan segera tersedia');
      },
    );
  }

  // Add this method to confirm password update which was missing
  void _confirmPasswordUpdate() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    // Validate password fields
    if (_currentPasswordController.text.isEmpty) {
      _showErrorSnackBar('Password saat ini tidak boleh kosong');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar('Password baru tidak boleh kosong');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Konfirmasi password tidak boleh kosong');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Password baru dan konfirmasi password tidak cocok');
      return;
    }

    ConfirmationDialog.show(
      context: context,
      title: 'Perbarui Password',
      message: 'Apakah Anda yakin ingin mengubah password Anda?',
      onConfirm: _updatePassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        // Return the update status when navigating back
        Navigator.of(context).pop(_profileUpdated);
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF5),
        body: Stack(
          children: [
            // Background decorations
            _buildBackgroundDecorations(size),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context),

                  // Main content - scrollable with loading state
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF306424)),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildMainContent(context),
                            ),
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

  Widget _buildHeader(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context, _profileUpdated),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF306424)),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Profil Pengguna',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile summary card
          _buildProfileSummaryCard(),

          const SizedBox(height: 24),

          // Profile settings section
          _buildSectionHeader('Pengaturan Profil'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsItem(
              icon: Icons.camera_alt_outlined,
              title: 'Perbarui Foto Profil',
              onTap: _showImageSourceOptions,
            ),
            _buildDivider(),
            _buildUsernameSection(),
            _buildDivider(),
            _buildPhoneSection(),
            _buildDivider(),
            _buildEmailSection(),
          ]),

          const SizedBox(height: 24),

          // Security settings section
          _buildSectionHeader('Pengaturan Keamanan'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildPasswordSection(),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.fingerprint,
              title: 'Biometric Authentication',
              subtitle: 'Aktifkan login dengan sidik jari',
              isSwitch: true,
              onSwitchChanged: (value) {
                // Implement biometric settings
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: 'Kelola pengaturan notifikasi',
              onTap: () {
                // Implement notification settings
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Logout button
          _buildLogoutButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF306424).withOpacity(0.9),
            const Color(0xFF4C8C3D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF306424).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: _getProfileImage(),
                      child: _shouldShowDefaultIcon()
                          ? const Icon(Icons.person,
                              size: 40, color: Color(0xFF306424))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Color(0xFF306424),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userProfile['username'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildProfileInfoItem(
                      Icons.phone_android,
                      _userProfile['phoneNumber'] ?? '-',
                    ),
                    const SizedBox(height: 4),
                    _buildProfileInfoItem(
                      Icons.email_outlined,
                      _userProfile['email'] ?? '-',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: Colors.white.withOpacity(0.2)),

          const SizedBox(height: 20),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStat(
                  'Bergabung', _formatDate(_userProfile['registrationDate'])),
              _buildProfileStatDivider(),
              _buildProfileStat(
                  'Pengiriman', '${_userProfile['totalDeliveries'] ?? 0}'),
              _buildProfileStatDivider(),
              _buildProfileStat(
                  'Sukses', _formatPercentage(_userProfile['percentage'])),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to format percentage
  String _formatPercentage(dynamic percentage) {
    if (percentage == null) {
      return '0.0 %';
    }

    try {
      final double value = percentage is double
          ? percentage
          : double.parse(percentage.toString());
      return '${value.toStringAsFixed(1)} %';
    } catch (e) {
      debugPrint('Error formatting percentage: $e');
      return '0.0 %';
    }
  }

  Widget _buildProfileInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfileStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isSwitch = false,
    Function(bool)? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    final contentWidget = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF306424).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF306424), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isSwitch)
          Switch(
            value: false, // Initial value
            onChanged: onSwitchChanged,
            activeColor: const Color(0xFF306424),
          )
        else
          const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );

    if (onTap != null && !isSwitch) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: contentWidget,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: contentWidget,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5);
  }

  Widget _buildUsernameSection() {
    if (_isEditingUsername) {
      final bool usernameHasChanged =
          _usernameController.text.trim() != _userProfile['username'];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbarui Username',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Masukkan username baru',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF306424),
                  size: 20,
                ),
                // Display error message if there is one
                errorText: _usernameError,
                helperText: 'Username harus 3-20 karakter (huruf, angka, _)',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              // Disable the field while updating
              enabled: !_isUpdatingUsername,
              onChanged: (value) {
                // Trigger a rebuild to update disabled state of button
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUpdatingUsername
                      ? null
                      : () {
                          setState(() {
                            _usernameController.text =
                                _userProfile['username'] ?? '';
                            _isEditingUsername = false;
                            _usernameError = null;
                          });
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_isUpdatingUsername || !usernameHasChanged)
                      ? null
                      : _confirmUsernameUpdate,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF306424),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUpdatingUsername
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return _buildSettingsItem(
        icon: Icons.person_outline,
        title: 'Perbarui Username',
        subtitle: _userProfile['username'] ?? '-',
        onTap: () {
          setState(() {
            _isEditingUsername = true;
          });
        },
      );
    }
  }

  // Update the phone section UI to include validation and disable button when unchanged
  Widget _buildPhoneSection() {
    if (_isEditingPhone) {
      final bool phoneHasChanged =
          _phoneController.text.trim() != _userProfile['phoneNumber'];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbarui Nomor Telepon',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Masukkan nomor telepon baru',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.phone_android,
                  color: Color(0xFF306424),
                  size: 20,
                ),
                errorText: _phoneError,
                helperText: 'Contoh: 081234567890 atau +6281234567890',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isUpdatingPhone,
              onChanged: (value) {
                // Trigger a rebuild to update disabled state of button
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUpdatingPhone
                      ? null
                      : () {
                          setState(() {
                            _phoneController.text =
                                _userProfile['phoneNumber'] ?? '';
                            _isEditingPhone = false;
                            _phoneError = null;
                          });
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_isUpdatingPhone || !phoneHasChanged)
                      ? null
                      : _confirmPhoneUpdate,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF306424),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUpdatingPhone
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return _buildSettingsItem(
        icon: Icons.phone_android,
        title: 'Perbarui Nomor Telepon',
        subtitle: _userProfile['phoneNumber'] ?? '-',
        onTap: () {
          setState(() {
            _isEditingPhone = true;
          });
        },
      );
    }
  }

  // Fix the email section to call _confirmEmailUpdate without arguments
  Widget _buildEmailSection() {
    if (_isEditingEmail) {
      final bool emailHasChanged =
          _emailController.text.trim() != _userProfile['email'];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbarui Email',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Masukkan email baru',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF306424),
                  size: 20,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _emailController.text = _userProfile['email'] ?? '';
                      _isEditingEmail = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: !emailHasChanged
                      ? null
                      : _confirmEmailUpdate, // Fixed: removed parameter
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF306424),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return _buildSettingsItem(
        icon: Icons.email_outlined,
        title: 'Perbarui Email',
        subtitle: _userProfile['email'] ?? '-',
        onTap: () {
          setState(() {
            _isEditingEmail = true;
          });
        },
      );
    }
  }

  // Update the password section UI to show validation errors and loading state
  Widget _buildPasswordSection() {
    if (_isEditingPassword) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbarui Password',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _passwordError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Current password
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password saat ini',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF306424),
                  size: 20,
                ),
              ),
              enabled: !_isUpdatingPassword,
            ),
            const SizedBox(height: 12),
            // New password
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password baru',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF306424),
                  size: 20,
                ),
                helperText: 'Minimal 8 karakter',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              enabled: !_isUpdatingPassword,
            ),
            const SizedBox(height: 12),
            // Confirm new password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Konfirmasi password baru',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF306424),
                  size: 20,
                ),
              ),
              enabled: !_isUpdatingPassword,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUpdatingPassword
                      ? null
                      : () {
                          setState(() {
                            _isEditingPassword = false;
                            _passwordError = null;
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _isUpdatingPassword ? null : _confirmPasswordUpdate,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF306424),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUpdatingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return _buildSettingsItem(
        icon: Icons.lock_outline,
        title: 'Perbarui Password',
        subtitle: '••••••••',
        onTap: () {
          setState(() {
            _isEditingPassword = true;
          });
        },
      );
    }
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: _showLogoutConfirmation,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF306424),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF306424), width: 1.5),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF306424).withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
