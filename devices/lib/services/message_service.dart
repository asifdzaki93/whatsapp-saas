import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/api.dart';

class MessageService {
  Future<List<Message>> getMessages(
    int ticketId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print(
        'Requesting messages for ticket $ticketId from: ${Api.baseUrl}/messages/$ticketId?page=$page&limit=$limit',
      );

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/messages/$ticketId?page=$page&limit=$limit'),
        headers: await Api.getHeaders(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['messages'] == null) {
          print('No messages found');
          return [];
        }

        final List<dynamic> messagesJson = data['messages'];
        print('Found ${messagesJson.length} messages');

        return messagesJson.map((json) {
          // Pastikan semua field yang diperlukan ada
          json['mediaType'] = json['mediaType'] ?? 'text';
          json['mediaUrl'] = Api.fixMediaUrl(json['mediaUrl']);
          json['mediaName'] = json['mediaName'] ?? '';
          json['mediaSize'] = json['mediaSize'] ?? '';
          json['mediaDuration'] = json['mediaDuration'] ?? '';
          json['locationName'] = json['locationName'] ?? '';
          json['fromMe'] = json['fromMe'] ?? false;
          json['read'] = json['read'] ?? false;
          json['isDeleted'] = json['isDeleted'] ?? false;
          json['isEdited'] = json['isEdited'] ?? false;

          // Pastikan contact ada jika diperlukan
          if (json['contact'] == null) {
            json['contact'] = {
              'id': null,
              'name': null,
              'email': null,
              'number': null,
              'profilePicUrl': null,
              'ignoreMessages': false,
            };
          }

          return Message.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading messages: $e');
      throw Exception('Error loading messages: $e');
    }
  }

  Future<Message> sendMessage(int ticketId, String content) async {
    try {
      print('Sending message to ticket $ticketId');

      final response = await http.post(
        Uri.parse('${Api.baseUrl}/messages/$ticketId'),
        headers: await Api.getHeaders(),
        body: json.encode({
          'body': content,
          'fromMe': true,
          'mediaType': 'text',
          'ticketId': ticketId,
          'read': true,
          'isDeleted': false,
          'isEdited': false,
          'remoteJid': null,
          'participant': null,
          'ack': 0,
          'mediaName': '',
          'mediaSize': '',
          'mediaDuration': '',
          'locationName': '',
          'dataJson': json.encode({
            'key': {
              'remoteJid': null,
              'fromMe': true,
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
            },
            'message': {
              'extendedTextMessage': {'text': content},
            },
          }),
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Pastikan semua field yang diperlukan ada
        data['mediaType'] = data['mediaType'] ?? 'text';
        data['mediaUrl'] = Api.fixMediaUrl(data['mediaUrl']);
        data['mediaName'] = data['mediaName'] ?? '';
        data['mediaSize'] = data['mediaSize'] ?? '';
        data['mediaDuration'] = data['mediaDuration'] ?? '';
        data['locationName'] = data['locationName'] ?? '';
        data['fromMe'] = data['fromMe'] ?? true;
        data['read'] = data['read'] ?? true;
        data['isDeleted'] = data['isDeleted'] ?? false;
        data['isEdited'] = data['isEdited'] ?? false;

        // Pastikan contact ada jika diperlukan
        if (data['contact'] == null) {
          data['contact'] = {
            'id': null,
            'name': null,
            'email': null,
            'number': null,
            'profilePicUrl': null,
            'ignoreMessages': false,
          };
        }

        return Message.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  Future<void> markAsRead(int messageId) async {
    try {
      final response = await http.put(
        Uri.parse('${Api.baseUrl}/messages/$messageId/read'),
        headers: await Api.getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark message as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error marking message as read: $e');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Api.baseUrl}/messages/$messageId'),
        headers: await Api.getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }
}
