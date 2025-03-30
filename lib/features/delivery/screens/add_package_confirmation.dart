import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPackageConfirmationScreen extends StatefulWidget {
  final File imageFile;

  const AddPackageConfirmationScreen({Key? key, required this.imageFile})
    : super(key: key);

  @override
  State<AddPackageConfirmationScreen> createState() =>
      _AddPackageConfirmationScreenState();
}

class _AddPackageConfirmationScreenState
    extends State<AddPackageConfirmationScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isProcessing = false;
  String? _ocrResult;

  @override
  void initState() {
    super.initState();
    // TODO: Implement OCR processing here
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate OCR processing
      await Future.delayed(const Duration(seconds: 2));
      // TODO: Replace with actual OCR implementation
      setState(() {
        _ocrResult = 'PKT-123456';
        _idController.text = _ocrResult ?? '';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses gambar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retakePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    AddPackageConfirmationScreen(imageFile: File(photo.path)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelivery() {
    if (_idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Pengiriman tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement delivery confirmation logic
    // For now, just show success message and pop
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengiriman berhasil ditambahkan'),
        backgroundColor: Color(0xFF306424),
      ),
    );
    Navigator.pop(context);
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
          'Konfirmasi Pengiriman',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(widget.imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 30),

              // ID Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    const Text(
                      'ID Pengiriman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _isProcessing
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF306424),
                            ),
                          ),
                        )
                        : TextField(
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan ID Pengiriman',
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.qr_code,
                              color: Color(0xFF306424),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  // Retake Photo Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retakePhoto,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF306424),
                        side: const BorderSide(color: Color(0xFF306424)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Ambil Ulang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Confirm Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmDelivery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF306424),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Konfirmasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }
}
