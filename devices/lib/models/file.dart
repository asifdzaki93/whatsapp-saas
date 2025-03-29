class FileModel {
  final int id;
  final String name;
  final String message;
  final List<FileOption> options;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileModel({
    required this.id,
    required this.name,
    required this.message,
    required this.options,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      name: json['name'],
      message: json['message'],
      options:
          (json['options'] as List)
              .map((option) => FileOption.fromJson(option))
              .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'message': message,
      'options': options.map((option) => option.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FileOption {
  final int id;
  final int fileId;
  final String name;
  final String path;
  final String mediaType;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileOption({
    required this.id,
    required this.fileId,
    required this.name,
    required this.path,
    required this.mediaType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FileOption.fromJson(Map<String, dynamic> json) {
    return FileOption(
      id: json['id'],
      fileId: json['fileId'],
      name: json['name'],
      path: json['path'],
      mediaType: json['mediaType'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileId': fileId,
      'name': name,
      'path': path,
      'mediaType': mediaType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
