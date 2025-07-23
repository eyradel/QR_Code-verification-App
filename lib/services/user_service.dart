import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class UserService {
  static Future<http.Response> fetchCurrentUser() async {
    String? accessToken = await SecureStorage.read('access_token');
    return await http.get(
      Uri.parse('https://services-7tfs.onrender.com/auth/users/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  static Future<http.Response> fetchUserByQr(String qrUrl) async {
    String? accessToken = await SecureStorage.read('access_token');
    return await http.get(
      Uri.parse(qrUrl),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  static Future<http.Response> lookupUserById(int userId) async {
    String? accessToken = await SecureStorage.read('access_token');
    return await http.get(
      Uri.parse('https://services-7tfs.onrender.com/auth/users/lookup/$userId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
} 