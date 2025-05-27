import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheHelper {
  // Cache buster untuk memaksa reload gambar
  static String addCacheBuster(String url) {
    if (url.isEmpty) return url;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}cache_bust=$timestamp';
  }

  // Method untuk clear cache gambar tertentu
  static Future<void> clearImageCache(String url) async {
    try {
      await CachedNetworkImage.evictFromCache(url);
      // Juga clear dengan berbagai variasi cache buster
      final baseUrl = url.split('?')[0];
      await CachedNetworkImage.evictFromCache(baseUrl);

      // Force clear Flutter's network image cache as well
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  // Method untuk clear semua cache gambar
  static Future<void> clearAllImageCache() async {
    try {
      // Clear Flutter's default image cache
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('Error clearing all image cache: $e');
    }
  }

  // Widget helper untuk menampilkan gambar profile dengan cache control
  static Widget buildProfileImage({
    required String? imageUrl,
    required double radius,
    Widget? placeholder,
    Widget? errorWidget,
    bool forceCacheBust = false,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            ),
          );
    }

    // Add cache buster if needed
    final finalUrl = forceCacheBust ? addCacheBuster(imageUrl) : imageUrl;

    return CachedNetworkImage(
      imageUrl: finalUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) =>
          placeholder ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            ),
          ),
      // Custom cache key untuk memastikan refresh
      cacheKey: forceCacheBust ? finalUrl : null,
    );
  }

  // Method khusus untuk force refresh profile image
  static Future<void> forceRefreshProfileImage(
      String imageUrl, BuildContext context) async {
    try {
      // Clear cache
      await clearImageCache(imageUrl);

      // Preload gambar dengan cache buster
      final cacheBustedUrl = addCacheBuster(imageUrl);
      await precacheImage(NetworkImage(cacheBustedUrl), context);
    } catch (e) {
      debugPrint('Error force refreshing profile image: $e');
    }
  }
}
