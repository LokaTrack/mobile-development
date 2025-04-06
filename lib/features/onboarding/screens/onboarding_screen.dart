import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lokatrack/features/onboarding/models/onboarding_page_model.dart';
import 'package:lokatrack/features/onboarding/services/onboarding_service.dart';
import 'package:lokatrack/features/onboarding/widgets/animated_button.dart';
import 'package:lokatrack/features/onboarding/widgets/particle_background.dart';
import 'package:lokatrack/features/onboarding/widgets/progress_bar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({Key? key, required this.onComplete})
      : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;

  // Content animations
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Icon animations
  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotateAnimation;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for better visual experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Initialize content animation controller
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create fade-in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeIn,
    ));

    // Create slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    ));

    // Initialize icon animation controller
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create icon scale animation
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Create icon rotation animation
    _iconRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticInOut),
    ));

    // Start animations
    _contentAnimationController.forward();
    _iconAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnimationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Reset and start animations for new page
    _contentAnimationController.reset();
    _iconAnimationController.reset();
    _contentAnimationController.forward();
    _iconAnimationController.forward();
  }

  void _goToNextPage() {
    final nextPage = _currentPage + 1;
    if (nextPage < onboardingPages.length) {
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await _onboardingService.completeOnboarding();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Use the colors from the model
    final appGreen = const Color(0xFF306424); // LokaTrack's signature green
    final appLightGreen =
        const Color(0xFFE9F6E5); // Light green from login screen

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background with subtle gradient matching login screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromRGBO(
                      235, 245, 235, 1), // Slightly greener top color
                  const Color.fromRGBO(
                      225, 242, 225, 1), // More green mid gradient
                  const Color.fromRGBO(
                      230, 248, 230, 1), // Greener bottom shade
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Particle background with a more subtle appearance
          ParticleBackground(
            baseColor: appGreen.withOpacity(0.4), // More subtle particles
            numberOfParticles: 20, // Slightly fewer particles
          ),

          SafeArea(
            child: Column(
              children: [
                // Top navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (hidden on first page)
                      _currentPage > 0
                          ? IconButton(
                              icon:
                                  const Icon(Icons.arrow_back_ios_new_rounded),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                              color: appGreen,
                            )
                          : const SizedBox(
                              width: 48), // Placeholder for alignment

                      // Skip button
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            color: appGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress bar with LokaTrack's green
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ProgressBar(
                    currentPage: _currentPage,
                    totalPages: onboardingPages.length,
                    activeColor: appGreen,
                    height: 4.0,
                    inactiveColor: Colors.grey.withOpacity(0.3),
                  ),
                ),

                // LokaTrack Logo - larger and more compact
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                  child: Image.asset(
                    'assets/images/lokatrack_logo.png',
                    height: 110, // Increased from 80 to 110
                  ),
                ),

                // Page view content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: onboardingPages.length,
                    itemBuilder: (context, index) {
                      final page = onboardingPages[index];
                      return _buildOnboardingPage(page);
                    },
                  ),
                ),

                // Page indicator dots with LokaTrack colors
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingPages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: appGreen,
                      dotColor: appLightGreen.withOpacity(0.7),
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                      expansionFactor: 4,
                    ),
                  ),
                ),

                // Text showing progress
                Text(
                  '${_currentPage + 1}/${onboardingPages.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Next/Get Started button - more compact and modern
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 30.0, left: 40, right: 40, top: 15),
                  child: AnimatedButton(
                    text: _currentPage == onboardingPages.length - 1
                        ? 'Mulai Sekarang'
                        : 'Selanjutnya',
                    onPressed: _goToNextPage,
                    backgroundColor: appGreen,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPageModel page) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Adding extra space at the top to move the icon down
              const SizedBox(height: 30),

              // Icon with animated container - moved down to avoid shadow clipping
              AnimatedBuilder(
                animation: _iconAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _iconRotateAnimation.value,
                      child: Container(
                        height: 160, // Made slightly smaller
                        width: 160, // Made slightly smaller
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              page.iconColor
                                  .withOpacity(0.15), // Reduced opacity
                              Colors.transparent,
                            ],
                            stops: const [0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: page.iconColor.withOpacity(
                                  0.2), // Lighter shadow (from 0.3)
                              blurRadius: 25, // Increased blur radius (from 20)
                              spreadRadius: 1, // Reduced spread (from 2)
                              offset: const Offset(0, 4),
                            ),
                            // Adding a second, more diffused shadow for a subtle glow effect
                            BoxShadow(
                              color: page.iconColor.withOpacity(0.05),
                              blurRadius: 35,
                              spreadRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            page.icon,
                            size:
                                70, // Made slightly smaller to match container
                            color: page.iconColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
