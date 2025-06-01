import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'features/auth/screens/login_screen.dart';
import 'features/delivery/screens/home_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/services/onboarding_service.dart';
import 'features/delivery/screens/return_confirmation_screen.dart';
import 'features/delivery/models/package.dart';

void main() {
  // error handling for the entire app
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(const MyApp());
  }, (error, stack) {
    // Log any errors here
    print('Global error: $error');
    print('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LokaTrack',
      theme: ThemeData(
        primaryColor: const Color(0xFF306424),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF306424),
          primary: const Color(0xFF306424),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/return-confirmation': (context) {
          // Ambil arguments yang dikirimkan
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null) {
            // Fallback jika tidak ada arguments
            return const HomeScreen();
          } // Get package from args or create a more descriptive default package
          final package = args['package'] as Package? ??
              Package(
                  id: args['deliveryId'] as String? ?? 'Unknown',
                  recipient: 'Data tidak tersedia',
                  address: 'Data tidak tersedia',
                  status: PackageStatus.checkin,
                  items: 'Items',
                  scheduledDelivery: DateTime.now(),
                  totalAmount: 0,
                  weight: 0,
                  notes: '');

          // Kirim data ke ReturnConfirmationScreen
          return ReturnConfirmationScreen(
            package: package,
            imagePath:
                (args['capturedImages'] as List<dynamic>?)?.first.toString() ??
                    '',
            returnReason: 'Barang tidak sesuai',
            notes: '',
            ocrResults: args['ocrResults'] as Map<String, dynamic>? ?? {},
          );
        },
      },
      // Use a builder to handle text scaling for the entire app
      builder: (context, child) {
        return MediaQuery(
          // Fix text scale factor to 1.0
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const SplashScreen(),
      // initialRoute: '/',
    );
  }
}

// Create a splash screen to handle initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Allow UI to render completely first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startNavigation();
    });
  }

  Future<void> _startNavigation() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Short delay to ensure everything is ready
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    try {
      final authService = AuthService();
      final onboardingService = OnboardingService();

      // Check onboarding status
      final hasSeenOnboarding = await onboardingService.hasSeenOnboarding();
      if (!mounted) return;

      if (!hasSeenOnboarding) {
        // Navigate to onboarding with a more direct approach
        _navigateToOnboarding();
        return;
      }

      // Check login status
      final isLoggedIn = await authService.isLoggedIn();
      if (!mounted) return;

      // Navigate based on login status
      if (isLoggedIn) {
        _navigateToHome();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      print('Navigation error: $e');
      if (mounted) {
        _navigateToLogin(); // Fallback
      }
    }
  }

  void _navigateToOnboarding() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          onComplete: () async {
            try {
              // Use the existing completeOnboarding method
              final onboardingService = OnboardingService();
              await onboardingService.completeOnboarding();

              print("Onboarding completed, navigating to login...");

              // Use direct navigation to LoginScreen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // This removes all previous routes
              );
            } catch (e) {
              print("Error during onboarding completion: $e");
              // Fallback navigation that doesn't rely on context
              WidgetsBinding.instance.addPostFrameCallback((_) {
                runApp(MaterialApp(home: const LoginScreen()));
              });
            }
          },
        ),
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoadingScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF306424).withValues(alpha: 0.2),
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
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF306424)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memuat LokaTrack...',
              style: TextStyle(
                color: Color(0xFF306424),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the AuthCheckScreen for backward compatibility
class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
