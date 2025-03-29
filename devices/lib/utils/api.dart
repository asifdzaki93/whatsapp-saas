import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Api {
  static const String baseUrl = 'http://192.168.100.164:9003';
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> getHeaders() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      // Coba refresh token jika tidak ada
      final refreshed = await refreshToken();
      if (!refreshed) {
        throw Exception('Token tidak ditemukan dan gagal memperbarui token');
      }
      // Ambil token baru setelah refresh
      final newToken = await _storage.read(key: 'token');
      if (newToken == null) {
        throw Exception('Gagal mendapatkan token baru');
      }
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $newToken',
      };
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> refreshToken() async {
    try {
      final email = await _storage.read(key: 'email');
      final password = await _storage.read(key: 'password');

      if (email == null || password == null) {
        print('Email atau password tidak ditemukan');
        return false;
      }

      print('Mencoba refresh token dengan email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      print('Refresh token response status: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        print('Token berhasil diperbarui');
        return true;
      }

      print('Gagal refresh token: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  static Future<http.Response> handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print('Token kadaluarsa, mencoba refresh token');
      final refreshed = await refreshToken();
      if (refreshed) {
        // Retry the request with new token
        final headers = await getHeaders();
        final url = response.request?.url;
        if (url != null) {
          print(
            'Mencoba request ulang dengan token baru ke: ${url.toString()}',
          );
          return await http.get(Uri.parse(url.toString()), headers: headers);
        }
      }
    }
    return response;
  }
}
