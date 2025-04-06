import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final Color baseColor;
  final int numberOfParticles;

  const ParticleBackground({
    Key? key,
    required this.baseColor,
    this.numberOfParticles = 30,
  }) : super(key: key);

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeParticles();
  }

  void _initializeParticles() {
    // Initialize controllers and animations
    _controllers = List.generate(
      widget.numberOfParticles,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: _random.nextInt(12000) + 8000,
        ), // Random duration between 8-20 seconds
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.linear,
        ),
      );
    }).toList();

    // Create particles
    for (int i = 0; i < widget.numberOfParticles; i++) {
      _particles.add(Particle(
        baseColor: widget.baseColor,
        random: _random,
      ));

      // Add listener to restart animation when complete
      _controllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _particles[i] = Particle(
            baseColor: widget.baseColor,
            random: _random,
          );
          _controllers[i].reset();
          _controllers[i].forward();
        }
      });

      // Start animation with a random delay
      Future.delayed(Duration(milliseconds: _random.nextInt(5000)), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ParticleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseColor != widget.baseColor) {
      // Update particle colors when the base color changes
      for (var particle in _particles) {
        particle.updateColor(widget.baseColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: List.generate(widget.numberOfParticles, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                final particle = _particles[index];
                final progress = _animations[index].value;

                return Positioned(
                  left: particle.startX +
                      (particle.endX - particle.startX) * progress,
                  top: particle.startY +
                      (particle.endY - particle.startY) * progress,
                  child: Opacity(
                    opacity: particle.opacity *
                        (progress < 0.5
                            ? progress * 2
                            : (1 - progress) * 2), // Fade in and out
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: particle.color.withOpacity(0.3),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class Particle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  double opacity;
  late Color color;

  Particle({
    required Color baseColor,
    required Random random,
  })  : startX = random.nextDouble() * 400 - 50,
        startY = random.nextDouble() * 800 + 50,
        endX = random.nextDouble() * 400 - 50,
        endY = random.nextDouble() * -200,
        size = random.nextDouble() * 8 + 2,
        opacity = random.nextDouble() * 0.4 + 0.1 {
    // Randomize the color slightly
    final hslColor = HSLColor.fromColor(baseColor);
    color = hslColor
        .withLightness(min(1.0, hslColor.lightness + random.nextDouble() * 0.3))
        .withSaturation(
            min(1.0, hslColor.saturation + random.nextDouble() * 0.2))
        .toColor();
  }

  void updateColor(Color baseColor) {
    final hslColor = HSLColor.fromColor(baseColor);
    final random = Random();
    color = hslColor
        .withLightness(min(1.0, hslColor.lightness + random.nextDouble() * 0.3))
        .withSaturation(
            min(1.0, hslColor.saturation + random.nextDouble() * 0.2))
        .toColor();
  }
}
