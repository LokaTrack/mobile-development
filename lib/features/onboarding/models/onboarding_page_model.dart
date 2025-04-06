import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon; // Using icons instead of images for simplicity
  final Color iconColor;
  final String animationPath; // For Lottie animations if we decide to use them

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.animationPath = '',
  });
}

// Updated green colors to match LokaTrack's identity
final Color primaryGreen = const Color(0xFF306424); // LokaTrack's primary green
final Color lightGreen =
    const Color(0xFFDEF7E5); // Light fresh green for gradient/background

// Sample onboarding data for delivery drivers
final List<OnboardingPageModel> onboardingPages = [
  OnboardingPageModel(
    title: 'Selamat Datang di LokaTrack',
    description:
        'Aplikasi untuk membantu Anda mencatat dan mengelola pengiriman dengan mudah dan efisien.',
    icon: Icons.location_on_rounded,
    iconColor: primaryGreen,
  ),
  OnboardingPageModel(
    title: 'Akses Lokasi Pengiriman',
    description:
        'Dapatkan informasi alamat pengiriman dan akses langsung ke Google Maps untuk memudahkan Anda menemukan lokasi pengiriman.',
    icon: Icons.map_rounded,
    iconColor: primaryGreen,
  ),
  OnboardingPageModel(
    title: 'Kelola Pengiriman',
    description:
        'Pantau status pengiriman, konfirmasi penerimaan, dan dapatkan bukti pengiriman dengan mudah.',
    icon: Icons.local_shipping_rounded,
    iconColor: primaryGreen,
  ),
  OnboardingPageModel(
    title: 'Laporkan & Analisis',
    description:
        'Buat laporan pengiriman dan lihat analisis performa Anda untuk meningkatkan efisiensi.',
    icon: Icons.analytics_rounded,
    iconColor: primaryGreen,
  ),
];
