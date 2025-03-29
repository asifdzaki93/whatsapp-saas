import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class Contact {
  final int? id;
  final String? name;
  final String? email;
  final String? number;
  final String? profilePicUrl;
  final bool? ignoreMessages;

  Contact({
    this.id,
    this.name,
    this.email,
    this.number,
    this.profilePicUrl,
    this.ignoreMessages,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      number: json['number'],
      profilePicUrl: json['profilePicUrl'],
      ignoreMessages: json['ignoreMessages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'number': number,
      'profilePicUrl': profilePicUrl,
      'ignoreMessages': ignoreMessages,
    };
  }
}

class Message {
  final String id;
  final String? body;
  final String? mediaType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? mediaName;
  final String? mediaSize;
  final String? mediaDuration;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool fromMe;
  final bool read;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Contact? contact;
  final int ticketId;
  final String? quotedMsgId;
  final Message? quotedMsg;
  final String? remoteJid;
  final String? participant;
  final int? ack;
  final String? dataJson;

  Message({
    required this.id,
    this.body,
    this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaName,
    this.mediaSize,
    this.mediaDuration,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.fromMe,
    required this.read,
    required this.isDeleted,
    required this.isEdited,
    this.createdAt,
    this.updatedAt,
    this.contact,
    required this.ticketId,
    this.quotedMsgId,
    this.quotedMsg,
    this.remoteJid,
    this.participant,
    this.ack,
    this.dataJson,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      body: json['body'],
      mediaType: json['mediaType'],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      mediaName: json['mediaName'],
      mediaSize: json['mediaSize'],
      mediaDuration: json['mediaDuration'],
      locationName: json['locationName'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      fromMe: json['fromMe'] ?? false,
      read: json['read'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      contact:
          json['contact'] != null ? Contact.fromJson(json['contact']) : null,
      ticketId: json['ticketId'] ?? 0,
      quotedMsgId: json['quotedMsgId'],
      quotedMsg:
          json['quotedMsg'] != null
              ? Message.fromJson(json['quotedMsg'])
              : null,
      remoteJid: json['remoteJid'],
      participant: json['participant'],
      ack: json['ack'],
      dataJson: json['dataJson'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaName': mediaName,
      'mediaSize': mediaSize,
      'mediaDuration': mediaDuration,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'fromMe': fromMe,
      'read': read,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'contact': contact?.toJson(),
      'ticketId': ticketId,
      'quotedMsgId': quotedMsgId,
      'quotedMsg': quotedMsg?.toJson(),
      'remoteJid': remoteJid,
      'participant': participant,
      'ack': ack,
      'dataJson': dataJson,
    };
  }

  Message copyWith({
    String? id,
    String? body,
    String? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? mediaName,
    String? mediaSize,
    String? mediaDuration,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? fromMe,
    bool? read,
    bool? isDeleted,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
    Contact? contact,
    int? ticketId,
    String? quotedMsgId,
    Message? quotedMsg,
    String? remoteJid,
    String? participant,
    int? ack,
    String? dataJson,
  }) {
    return Message(
      id: id ?? this.id,
      body: body ?? this.body,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaName: mediaName ?? this.mediaName,
      mediaSize: mediaSize ?? this.mediaSize,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fromMe: fromMe ?? this.fromMe,
      read: read ?? this.read,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contact: contact ?? this.contact,
      ticketId: ticketId ?? this.ticketId,
      quotedMsgId: quotedMsgId ?? this.quotedMsgId,
      quotedMsg: quotedMsg ?? this.quotedMsg,
      remoteJid: remoteJid ?? this.remoteJid,
      participant: participant ?? this.participant,
      ack: ack ?? this.ack,
      dataJson: dataJson ?? this.dataJson,
    );
  }
}
