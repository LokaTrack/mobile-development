import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const String USER_DATA_KEY = 'user_data';
  static const String TOKEN_KEY = 'auth_token';
  static const String TOKEN_EXPIRY_KEY = 'token_expiry';

  // Menyimpan data user dan token
  Future<void> saveUserSession(
      Map<String, dynamic> userData, String token) async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan token
    await prefs.setString(TOKEN_KEY, token);

    // Simpan data user
    await prefs.setString(USER_DATA_KEY, jsonEncode(userData));

    // Parse dan simpan waktu kedaluwarsa token (jika ada dalam format JWT)
    try {
      if (token.split('.').length == 3) {
        final parts = token.split('.');
        final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

        if (payload.containsKey('exp')) {
          final expiryDate =
              DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
          await prefs.setString(TOKEN_EXPIRY_KEY, expiryDate.toIso8601String());
        }
      }
    } catch (e) {
      print('Error parsing token expiry: $e');
    }
  }

  // Mengambil token dari penyimpanan lokal
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  // Mengambil data user dari penyimpanan lokal
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(USER_DATA_KEY);

    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Memeriksa apakah pengguna sudah login dan token masih valid
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final expiryDateString = prefs.getString(TOKEN_EXPIRY_KEY);

    if (expiryDateString != null) {
      final expiryDate = DateTime.parse(expiryDateString);
      return expiryDate.isAfter(DateTime.now());
    }

    // Jika tidak ada tanggal kedaluwarsa, tetap anggap valid
    return true;
  }

  // Logout: Hapus semua data sesi
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(USER_DATA_KEY);
    await prefs.remove(TOKEN_EXPIRY_KEY);
  }
}
