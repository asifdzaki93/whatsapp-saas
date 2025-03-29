import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  static const String baseUrl = 'http://192.168.100.164:9003';

  static Future<Map<String, String>> getHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static String fixMediaUrl(String? url) {
    if (url == null) return '';
    if (url.contains('localhost')) {
      return url
          .replaceAll(':443', '')
          .replaceAll('localhost:9003', baseUrl.replaceAll('http://', ''));
    }
    return url;
  }
}
