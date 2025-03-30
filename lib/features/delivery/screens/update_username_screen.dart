import 'package:flutter/material.dart';

class UpdateUsernameScreen extends StatefulWidget {
  final String currentUsername;

  const UpdateUsernameScreen({Key? key, required this.currentUsername})
    : super(key: key);

  @override
  State<UpdateUsernameScreen> createState() => _UpdateUsernameScreenState();
}

class _UpdateUsernameScreenState extends State<UpdateUsernameScreen> {
  late final TextEditingController _usernameController;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool _isValidUsername(String username) {
    return username.length >= 3 && username.length <= 30;
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();

    if (!_isValidUsername(newUsername)) {
      setState(() {
        _errorText = 'Username harus memiliki 3-30 karakter';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // TODO: Implement API call to update username
      await Future.delayed(const Duration(seconds: 2)); // Simulated API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username berhasil diperbarui'),
            backgroundColor: Color(0xFF306424),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Gagal memperbarui username. Silakan coba lagi.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          'Update Username',
          style: TextStyle(
            color: Color(0xFF306424),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Username Baru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF306424),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan username baru',
                          errorText: _errorText,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF306424),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE9F6E5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF306424),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF306424),
                        ),
                        onChanged: (value) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Username akan digunakan untuk identifikasi akun Anda.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF306424),
                      foregroundColor:
                          Colors.white, // Mengubah warna teks menjadi putih
                      disabledBackgroundColor:
                          Colors.grey[300], // Warna button saat disabled
                      disabledForegroundColor:
                          Colors.grey[600], // Warna teks saat disabled
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _isLoading ? 'Memperbarui...' : 'Simpan Username',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF306424)),
              ),
            ),
        ],
      ),
    );
  }
}
