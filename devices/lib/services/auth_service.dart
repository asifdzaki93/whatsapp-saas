import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  User? _currentUser;

  Future<User> login({required String email, required String password}) async {
    try {
      print('=== Login Debug ===');
      print('Attempting login for: $email');

      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Saving token: ${data['token']}');
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        print('Token saved successfully');

        // Simpan data user
        _currentUser = User.fromJson(data['user']);
        print('User data saved: ${_currentUser?.toJson()}');
        return _currentUser!;
      } else {
        print('Login failed: ${response.statusCode}');
        throw Exception('Email atau kata sandi salah');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Gagal masuk: $e');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.envToken}',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'profile': 'admin',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mendaftar');
      }
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    return {'email': email, 'password': password};
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }

  Future<void> logout() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.baseUrl + ApiConfig.logout),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } finally {
      await _storage.deleteAll();
      _currentUser = null;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<User?> getCurrentUser() async {
    // Jika sudah ada data user, gunakan itu
    if (_currentUser != null) {
      print('Using cached user data: ${_currentUser?.toJson()}');
      return _currentUser;
    }

    final token = await _storage.read(key: 'token');
    print('=== Auth Debug ===');
    print('Token: $token');

    if (token == null) {
      print('Token is null');
      return null;
    }

    try {
      print('Fetching user data from: ${ApiConfig.baseUrl}/auth/me');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = User.fromJson(data);
        return _currentUser;
      } else {
        print('Failed to get user data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
