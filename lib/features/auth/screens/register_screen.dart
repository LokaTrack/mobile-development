import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Focus nodes for managing keyboard
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Scroll controller untuk memastikan field yang aktif selalu terlihat
  final ScrollController _scrollController = ScrollController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFocusListeners();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  void _setupFocusListeners() {
    _usernameFocusNode.addListener(_handleFocusChange);
    _emailFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleFocusChange);
    _confirmPasswordFocusNode.addListener(_handleFocusChange);
  }

  // Fungsi untuk menangani perubahan fokus dan scroll ke field yang aktif
  void _handleFocusChange() {
    if (_usernameFocusNode.hasFocus ||
        _emailFocusNode.hasFocus ||
        _passwordFocusNode.hasFocus ||
        _confirmPasswordFocusNode.hasFocus) {
      // Delay scroll sedikit untuk memastikan keyboard sudah muncul
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _animationController.dispose();

    _usernameFocusNode.removeListener(_handleFocusChange);
    _emailFocusNode.removeListener(_handleFocusChange);
    _passwordFocusNode.removeListener(_handleFocusChange);
    _confirmPasswordFocusNode.removeListener(_handleFocusChange);

    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    // Clear previous errors
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });

    // Get input values
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false; // Validate username
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username tidak boleh kosong';
      });
      hasError = true;
    } else if (username.length < 3) {
      setState(() {
        _usernameError = 'Username minimal 3 karakter';
      });
      hasError = true;
    } else if (username.length > 20) {
      setState(() {
        _usernameError = 'Username maksimal 20 karakter';
      });
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(username)) {
      setState(() {
        _usernameError =
            'Username hanya boleh mengandung huruf, angka, underscore (_), dan spasi';
      });
      hasError = true;
    } else if (!RegExp(r'[a-zA-Z0-9]').hasMatch(username)) {
      setState(() {
        _usernameError =
            'Username harus mengandung setidaknya satu huruf atau angka';
      });
      hasError = true;
    }

    // Validate email
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong';
      });
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailError = 'Format email tidak valid';
      });
      hasError = true;
    }

    // Validate password
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong';
      });
      hasError = true;
    } else if (password.length < 6) {
      setState(() {
        _passwordError = 'Password minimal 6 karakter';
      });
      hasError = true;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Konfirmasi password tidak boleh kosong';
      });
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Password tidak cocok';
      });
      hasError = true;
    }

    if (hasError) return;

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.register(
        email: email,
        username: username,
        password: password,
        passwordConfirmation: confirmPassword,
      );

      if (!mounted) return;

      if (result['success']) {
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login'),
            backgroundColor: Color(0xFF306424),
          ),
        );
        Navigator.pop(context); // Return to login screen
      } else {
        // Show error message
        setState(() {
          _generalError =
              result['message'] ?? 'Terjadi kesalahan saat registrasi';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generalError = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      // Add this to dismiss keyboard when tapping outside text fields
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        // Set resizeToAvoidBottomInset ke false agar keyboard tidak mendorong konten ke atas
        resizeToAvoidBottomInset: false,
        body: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE9F6E5),
                Colors.white,
                const Color(0xFFE9F6E5).withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                _buildBackgroundDecorations(size),
                _buildScrollableContent(size, keyboardVisible),
              ],
            ),
          ),
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
              color: const Color(0xFF306424).withOpacity(0.1),
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
              color: const Color(0xFF306424).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Small bubble left
        Positioned(
          left: size.width * 0.2,
          top: size.height * 0.15,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Small bubble right
        Positioned(
          right: size.width * 0.15,
          bottom: size.height * 0.3,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFF306424).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent(Size size, bool keyboardVisible) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // Space at the top
            SizedBox(height: size.height * 0.04),

            // Logo Section
            _buildLogoSection(size),

            // Register Form Section
            _buildRegisterForm(),

            // Login Section
            _buildLoginSection(),

            // Extra space for keyboard
            SizedBox(height: keyboardVisible ? size.height * 0.3 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LokaTrack Logo from assets
            Container(
              width: size.width * 0.25, // Slightly smaller than login screen
              height: size.width * 0.25,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF306424).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/lokatrack_logo_small.png',
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 12),

            // App name
            const Text(
              'LokaTrack',
              style: TextStyle(
                color: Color(0xFF306424),
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Aplikasi Tracking Pengiriman Sayuran',
              style: TextStyle(
                color: Colors.black87.withOpacity(0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animationController.value) * 50),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Register Header
                  const Text(
                    'Daftar',
                    style: TextStyle(
                      color: Color(0xFF306424),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buat akun baru untuk mengakses layanan',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24), // Username Field
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    hintText: 'Username',
                    icon: Icons.person_outline,
                    errorText: _usernameError,
                    onEditingComplete: () {
                      FocusScope.of(context).requestFocus(_emailFocusNode);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    hintText: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onEditingComplete: () {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureValue: _obscurePassword,
                    errorText: _passwordError,
                    toggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    onEditingComplete: () {
                      FocusScope.of(
                        context,
                      ).requestFocus(_confirmPasswordFocusNode);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    hintText: 'Konfirmasi Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureValue: _obscureConfirmPassword,
                    errorText: _confirmPasswordError,
                    toggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    onEditingComplete: () {
                      _handleRegister();
                    },
                  ),

                  // General Error Message
                  if (_generalError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Register Button
                  _buildRegisterButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF306424),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // Add disabled style
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
            ),
            child: Text(
              _isLoading ? 'MENDAFTAR...' : 'DAFTAR',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sudah punya akun? ',
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: _navigateToLogin,
              child: const Text(
                'Masuk Sekarang',
                style: TextStyle(
                  color: Color(0xFF306424),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool? obscureValue,
    VoidCallback? toggleObscure,
    VoidCallback? onEditingComplete,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: Colors.red.shade300)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: isPassword ? (obscureValue ?? true) : false,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            onEditingComplete: onEditingComplete,
            textInputAction: onEditingComplete == _handleRegister
                ? TextInputAction.done
                : TextInputAction.next,
            enableInteractiveSelection: true,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(icon, color: const Color(0xFF306424), size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              suffixIcon: isPassword && toggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscureValue! ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: toggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
