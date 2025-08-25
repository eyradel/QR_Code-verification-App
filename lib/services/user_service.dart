import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class UserService {
  static const _base = 'https://services-backend-635062712814.europe-west1.run.app';

  static Future<http.Response> fetchCurrentUser() async {
    String? accessToken = await SecureStorage.read('access_token');
    return await http.get(
      Uri.parse('$_base/auth/users/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
  }

  static Future<http.Response> lookupUserById(int userId) async {
    String? accessToken = await SecureStorage.read('access_token');
    return await http.get(
      Uri.parse('$_base/auth/users/lookup/$userId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
  }
} 