import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OCRConfirmationScreen extends StatefulWidget {
  final File imageFile;
  final String detectedId;

  const OCRConfirmationScreen({
    Key? key,
    required this.imageFile,
    this.detectedId = 'PKT-001',
  }) : super(key: key);

  @override
  State<OCRConfirmationScreen> createState() => _OCRConfirmationScreenState();
}

class _OCRConfirmationScreenState extends State<OCRConfirmationScreen> {
  final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _idController.text = widget.detectedId;
  }

  void _handleReturn() {
    // Show confirmation dialog before returning package
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Retur'),
            content: const Text('Apakah Anda yakin ingin meretur paket ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF306424)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement return package logic here
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paket telah diretur'),
                      backgroundColor: Color(0xFF306424),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF306424),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Retur'),
              ),
            ],
          ),
    );
  }

  void _handleCheckIn() {
    // Show confirmation dialog before checking in package
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Check-in'),
            content: const Text('Apakah Anda yakin ingin check-in paket ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF306424)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement check-in package logic here
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paket berhasil di-check in'),
                      backgroundColor: Color(0xFF306424),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF306424),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Check-in'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF306424)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Konfirmasi Scan',
          style: TextStyle(
            color: Color(0xFF306424),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Captured Image Container
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

              // Detected ID Section
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
                      'ID Terdeteksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan ID Paket',
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
                  // Return Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleReturn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_return_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Return',
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
                  // Check-in Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleCheckIn,
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
                            'Check-in',
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
}
