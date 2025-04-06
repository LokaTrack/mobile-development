import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';

class AuthService {
  static const String baseUrl = 'https://lokatrack.me/api/v1';
  final AuthManager _authManager = AuthManager();

  // Mendapatkan token dari penyimpanan lokal
  Future<String?> getToken() async {
    return await _authManager.getToken();
  }

  // Memeriksa status login
  Future<bool> isLoggedIn() async {
    return await _authManager.isLoggedIn();
  }

  // Mendapatkan data user dari penyimpanan lokal
  Future<Map<String, dynamic>?> getUserData() async {
    return await _authManager.getUserData();
  }

  // Logout
  Future<void> logout() async {
    await _authManager.logout();
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
