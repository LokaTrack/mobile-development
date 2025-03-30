import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'update_profile_picture_screen.dart';
import 'update_username_screen.dart';
import 'update_phone_screen.dart';
import 'update_password_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  File? _profileImage;
  bool _isLoading = false;
  String _username = "Cornelius Yuli";
  String _phoneNumber = "081234567890";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Fetch user data from backend
      await Future.delayed(const Duration(seconds: 1));
      // Mock data loading
      setState(() {
        _username = "Cornelius Yuli";
        _phoneNumber = "081234567890";
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data profil');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F6E5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF306424), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                )
                : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Color(0xFF306424),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF306424),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF306424)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Color(0xFF306424),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF306424)),
              )
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF306424),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    _profileImage != null
                                        ? Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        )
                                        : Image.asset(
                                          'assets/images/default_profile.png',
                                          fit: BoxFit.cover,
                                        ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _username,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF306424),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _phoneNumber,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pengaturan Profil Section
                      _buildCategoryHeader('Pengaturan Profil'),
                      _buildSettingsItem(
                        title: 'Update Foto Profil',
                        icon: Icons.camera_alt_outlined,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const UpdateProfilePictureScreen(),
                            ),
                          );
                          if (result == true) {
                            // Refresh profile data after successful update
                            _loadInitialData();
                          }
                        },
                      ),
                      _buildSettingsItem(
                        title: 'Update Username',
                        icon: Icons.person_outline,
                        subtitle: _username,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UpdateUsernameScreen(
                                    currentUsername: _username,
                                  ),
                            ),
                          );
                          if (result == true) {
                            // Refresh profile data after successful update
                            _loadInitialData();
                          }
                        },
                      ),
                      _buildSettingsItem(
                        title: 'Update Nomor Telepon',
                        icon: Icons.phone_outlined,
                        subtitle: _phoneNumber,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UpdatePhoneScreen(
                                    currentPhone: _phoneNumber,
                                  ),
                            ),
                          );
                          if (result == true) {
                            // Refresh profile data after successful update
                            _loadInitialData();
                          }
                        },
                      ),

                      // Pengaturan Keamanan Section
                      _buildCategoryHeader('Pengaturan Keamanan'),
                      _buildSettingsItem(
                        title: 'Update Password',
                        icon: Icons.lock_outline,
                        subtitle: '••••••••',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const UpdatePasswordScreen(),
                            ),
                          );
                          if (result == true) {
                            // Password berhasil diperbarui
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password berhasil diperbarui'),
                                backgroundColor: Color(0xFF306424),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
