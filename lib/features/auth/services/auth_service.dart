import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';
import '../../../core/cache/data_cache.dart';

class AuthService {
  static const String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthManager _authManager = AuthManager();
  final DataCache _dataCache = DataCache();

  // Cache for session validation
  DateTime? _lastSessionCheck;
  bool? _lastSessionValid;
  static const Duration _sessionCacheTimeout = Duration(minutes: 5);
  // Mendapatkan token dari penyimpanan lokal
  Future<String?> getToken() async {
    return await _authManager.getToken();
  }

  // Mendapatkan user ID dari stored user data
  Future<String?> getCurrentUserId() async {
    final userData = await _authManager.getUserData();
    if (userData != null) {
      return userData['user']?['id']?.toString() ??
          userData['id']?.toString() ??
          userData['user']?['email']?.toString() ??
          userData['email']?.toString();
    }
    return null;
  }

  // Memeriksa status login dengan validasi session backend
  Future<bool> isLoggedIn() async {
    // First check if we have a valid token locally
    final hasValidToken = await _authManager.isLoggedIn();
    if (!hasValidToken) {
      _clearSessionCache();
      return false;
    }

    // Check if we have a recent valid session check in cache
    if (_lastSessionCheck != null &&
        _lastSessionValid != null &&
        DateTime.now().difference(_lastSessionCheck!) < _sessionCacheTimeout) {
      return _lastSessionValid!;
    }

    // Otherwise validate session with backend
    return await _validateSessionWithBackend();
  }

  // Validate session with backend server
  Future<bool> _validateSessionWithBackend() async {
    try {
      final token = await getToken();
      if (token == null) {
        _clearSessionCache();
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Cache the result
      _lastSessionCheck = DateTime.now();
      _lastSessionValid = response.statusCode == 200;

      // If we get 401, session is expired
      if (response.statusCode == 401) {
        // Session expired, clear local data and cache
        await logout();
        _clearSessionCache();
        return false;
      }

      // If successful response, session is still valid
      return response.statusCode == 200;
    } catch (e) {
      // If network error or other issues, assume session invalid for security
      _clearSessionCache();
      return false;
    }
  }

  // Clear session validation cache
  void _clearSessionCache() {
    _lastSessionCheck = null;
    _lastSessionValid = null;
  }

  // Mendapatkan data user dari penyimpanan lokal
  Future<Map<String, dynamic>?> getUserData() async {
    return await _authManager.getUserData();
  }

  // Logout
  Future<void> logout() async {
    // Clear data cache before logging out to ensure no user data persists
    _dataCache.clearAllForUserChange();

    // Clear AuthManager data
    await _authManager.logout();

    // Clear session cache
    _clearSessionCache();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
        'passwordConfirmation': passwordConfirmation,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Terjadi kesalahan saat registrasi',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Jika login sukses, simpan data user dan token
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final userData = responseData['data'];
          final token = userData['token'];

          // Extract user ID for cache management
          final userId = userData['user']?['id']?.toString() ??
              userData['id']?.toString() ??
              userData['user']?['email']?.toString() ??
              email; // fallback to email if no ID

          // Clear cache for any previous user and set new user ID
          _dataCache.setCurrentUserId(userId);

          // Simpan data user dan token ke shared preferences
          await _authManager.saveUserSession(userData, token);
        }

        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Login gagal, periksa email dan password anda',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat login: ${e.toString()}',
      };
    }
  }

  // Request OTP for password reset
  Future<Map<String, dynamic>> requestResetPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request-reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message':
              responseData['message'] ?? 'Kode OTP telah dikirim ke email Anda'
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Terjadi kesalahan saat mengirim OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: ${e.toString()}',
      };
    }
  }

  // Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'newPasswordConfirmation': newPasswordConfirmation,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Password berhasil direset!'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Terjadi kesalahan saat reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: ${e.toString()}',
      };
    }
  }
}
