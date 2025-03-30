import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdatePhoneScreen extends StatefulWidget {
  final String currentPhone;

  const UpdatePhoneScreen({Key? key, required this.currentPhone})
    : super(key: key);

  @override
  State<UpdatePhoneScreen> createState() => _UpdatePhoneScreenState();
}

class _UpdatePhoneScreenState extends State<UpdatePhoneScreen> {
  late final TextEditingController _phoneController;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    // Validasi nomor telepon Indonesia (minimal 10 digit, maksimal 13 digit)
    final phoneRegex = RegExp(r'^08[0-9]{8,11}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _updatePhone() async {
    final newPhone = _phoneController.text.trim();

    if (!_isValidPhone(newPhone)) {
      setState(() {
        _errorText = 'Masukkan nomor telepon yang valid (10-13 digit)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // TODO: Implement API call to update phone number
      await Future.delayed(const Duration(seconds: 2)); // Simulated API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor telepon berhasil diperbarui'),
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
              'Gagal memperbarui nomor telepon. Silakan coba lagi.',
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
          'Update Nomor Telepon',
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
                        'Nomor Telepon Baru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF306424),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nomor telepon baru',
                          errorText: _errorText,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
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
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                        ],
                        onChanged: (value) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pastikan nomor telepon yang Anda masukkan aktif dan dapat dihubungi.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF306424),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _isLoading ? 'Memperbarui...' : 'Simpan Nomor Telepon',
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
