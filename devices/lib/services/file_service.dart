import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file.dart';

class FileService {
  static const String baseUrl = 'http://192.168.1.2:8080';
  late SharedPreferences _storage;

  FileService() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = await SharedPreferences.getInstance();
  }

  Future<List<FileModel>> getFiles({
    String? searchParam,
    int pageNumber = 1,
  }) async {
    try {
      final token = _storage.getString('token');
      if (token == null) throw Exception('Token tidak ditemukan');

      final queryParams = {
        if (searchParam != null) 'searchParam': searchParam,
        'pageNumber': pageNumber.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/files',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['files'] as List)
            .map((file) => FileModel.fromJson(file))
            .toList();
      } else {
        throw Exception('Gagal mengambil data file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<FileModel> createFile({
    required String name,
    required String message,
    required List<Map<String, dynamic>> options,
  }) async {
    try {
      final token = _storage.getString('token');
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.post(
        Uri.parse('$baseUrl/files'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'message': message,
          'options': options,
        }),
      );

      if (response.statusCode == 200) {
        return FileModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal membuat file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> uploadFiles(int fileId, List<File> files) async {
    try {
      final token = _storage.getString('token');
      if (token == null) throw Exception('Token tidak ditemukan');

      final uri = Uri.parse('$baseUrl/files/uploadList/$fileId');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': 'Bearer $token'});

      for (var file in files) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final multipartFile = http.MultipartFile(
          'files',
          fileStream,
          fileLength,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200) {
        throw Exception('Gagal mengupload file: $jsonResponse');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteFile(int fileId) async {
    try {
      final token = _storage.getString('token');
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.delete(
        Uri.parse('$baseUrl/files/$fileId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
