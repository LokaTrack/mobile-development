import 'package:intl/intl.dart';

/// Helper class for consistent datetime parsing and formatting across the app
class DateTimeHelper {
  /// Parse datetime string from backend as local time (WIB) instead of UTC
  /// This fixes the timezone offset issue where backend sends local time
  /// but DateTime.parse() interprets it as UTC
  static DateTime? parseLocalDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;

    try {
      // Parse the datetime string and treat it as local time
      // Backend sends: "May 28, 2025, 7:18:22.035 AM"
      // We need to parse this as local time, not UTC

      // First try to parse with standard ISO format
      if (dateTimeString.contains('T') || dateTimeString.contains('Z')) {
        return DateTime.parse(dateTimeString).toLocal();
      }

      // Handle the specific format from backend: "May 28, 2025, 7:18:22.035 AM"
      try {
        final parsed = DateFormat('MMM dd, yyyy, h:mm:ss.SSS a', 'en_US')
            .parse(dateTimeString);
        // Create datetime in local timezone (WIB)
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        );
      } catch (e) {
        // Try alternative formats
        try {
          final parsed = DateFormat('MMM dd, yyyy, h:mm:ss a', 'en_US')
              .parse(dateTimeString);
          return DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
          );
        } catch (e) {
          // Fallback to standard parsing but treat as local
          final parsed = DateTime.parse(dateTimeString);
          // If it doesn't have timezone info, treat as local
          if (!dateTimeString.contains('Z') &&
              !dateTimeString.contains('+') &&
              !dateTimeString.contains('-')) {
            return DateTime(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
              parsed.millisecond,
            );
          }
          return parsed.toLocal();
        }
      }
    } catch (e) {
      print('Error parsing datetime: $dateTimeString, Error: $e');
      return null;
    }
  }

  /// Format datetime for display in Indonesian locale
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Tidak ada data';

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _getIndonesianMonth(dateTime.month);
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  /// Format date only (without time) for display
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Tidak ada data';

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _getIndonesianMonth(dateTime.month);
    final year = dateTime.year.toString();

    return '$day $month $year';
  }

  /// Format time only for display (HH:mm format)
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  /// Get Indonesian month abbreviation
  static String _getIndonesianMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  /// Check if datetime is today
  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Get relative time (e.g., "2 jam yang lalu")
  static String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Tidak diketahui';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}
