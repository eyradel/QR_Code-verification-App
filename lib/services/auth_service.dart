import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/secure_storage.dart';

class AuthService {
  static const _baseUrl = 'https://services-7tfs.onrender.com';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/token'),
      body: {
        'username': username,
        'password': password,
      },
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await SecureStorage.write('access_token', data['access_token']);
      return {'success': true};
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      return {'success': false, 'error': 'Invalid credentials or account not verified'};
    } else if (response.statusCode == 422) {
      return {'success': false, 'error': 'Validation error'};
    }
    return {'success': false, 'error': 'Unknown error'};
  }

  static Future<bool> verify(String username, String code) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'code': code}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> resendVerification(String username) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    return response.statusCode == 200;
  }
} 