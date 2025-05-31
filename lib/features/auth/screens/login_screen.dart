import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../delivery/screens/home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // Create a focus node to manage keyboard focus
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  // Scroll controller untuk memastikan field yang aktif selalu terlihat
  final ScrollController _scrollController = ScrollController();

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
    _emailFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleFocusChange);
  }

  // Fungsi untuk menangani perubahan fokus dan scroll ke field yang aktif
  void _handleFocusChange() {
    if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _emailFocusNode.removeListener(_handleFocusChange);
    _passwordFocusNode.removeListener(_handleFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    // Validate input
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

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

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(email: email, password: password);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Login berhasil - token dan data user sudah disimpan di AuthManager
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: Color(0xFF306424),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _generalError = result['message'] ?? 'Email atau password salah';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = 'Terjadi kesalahan saat login';
      });
    }
  }

  void _navigateToRegister() {
    // Navigasi ke halaman registrasi
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
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
            SizedBox(height: size.height * 0.05),

            // Logo Section
            _buildLogoSection(size),

            // Login Form Section
            _buildLoginForm(),

            // Registration Section
            _buildRegistrationSection(),

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
            // Lokatani Logo from assets
            Container(
              width: size.width * 0.3,
              height: size.width * 0.3,
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

            const SizedBox(height: 16),

            // App name
            const Text(
              'LokaTrack',
              style: TextStyle(
                color: Color(0xFF306424),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              'Aplikasi Tracking Pengiriman Sayuran',
              style: TextStyle(
                color: Colors.black87.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
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
                  // Login Header
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Color(0xFF306424),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan masuk untuk melanjutkan',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24), // Email Field
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
                    errorText: _passwordError,
                    onEditingComplete: () {
                      _handleLogin();
                    },
                  ),

                  // General Error Message
                  if (_generalError != null) ...[
                    const SizedBox(height: 12),
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

                  const SizedBox(height: 8),

                  // Forgot Password
                  _buildForgotPasswordButton(),

                  const SizedBox(height: 24),

                  // Login Button
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen()),
          );
        },
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Lupa Password?',
          style: TextStyle(
            color: Color(0xFF306424),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF306424),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'MASUK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum punya akun? ',
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: _navigateToRegister,
              child: const Text(
                'Daftar Sekarang',
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
    String? errorText,
    VoidCallback? onEditingComplete,
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
            obscureText: isPassword ? _obscurePassword : false,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            onEditingComplete: onEditingComplete,
            // Add these properties to improve keyboard behavior
            textInputAction:
                isPassword ? TextInputAction.done : TextInputAction.next,
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
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
