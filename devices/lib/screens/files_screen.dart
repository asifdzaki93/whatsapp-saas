import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file.dart';
import '../services/file_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _fileService = FileService();
  List<FileModel> _files = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _scrollController = ScrollController();
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadFiles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin akses penyimpanan diperlukan untuk mengelola file',
              ),
            ),
          );
        }
        return;
      }
    }
  }

  Future<void> _loadFiles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _files = [];
        _currentPage = 1;
        _hasMore = true;
      });
    }

    if (!_hasMore || _isLoading) return;

    try {
      setState(() => _isLoading = true);
      final files = await _fileService.getFiles(
        searchParam: _searchQuery,
        pageNumber: _currentPage,
      );

      setState(() {
        _files.addAll(files);
        _hasMore = files.length == 10; // Assuming page size is 10
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadFiles();
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result != null) {
        final platformFiles = result.files;
        final files = platformFiles.map((file) => File(file.path!)).toList();

        // Create file group
        final fileGroup = await _fileService.createFile(
          name: 'File Group ${DateTime.now().millisecondsSinceEpoch}',
          message: 'Uploaded files',
          options:
              platformFiles
                  .map(
                    (file) => {
                      'name': file.name,
                      'path': '',
                      'mediaType': _getMediaType(file.name),
                    },
                  )
                  .toList(),
        );

        // Upload files
        await _fileService.uploadFiles(fileGroup.id, files);

        // Refresh list
        _loadFiles(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  String _getMediaType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'avi', 'mov'].contains(extension)) {
      return 'video';
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx'].contains(extension)) {
      return 'document';
    }
    return 'other';
  }

  Widget _buildFileItem(FileModel file) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        leading: _buildFileIcon(file.options.first.mediaType),
        title: Text(file.name),
        subtitle: Text('${file.options.length} file'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteConfirmation(file),
        ),
        onTap: () {
          // TODO: Show file details
        },
      ),
    );
  }

  Widget _buildFileIcon(String mediaType) {
    IconData icon;
    Color color;

    switch (mediaType) {
      case 'image':
        icon = Icons.image;
        color = Colors.blue;
        break;
      case 'video':
        icon = Icons.video_library;
        color = Colors.red;
        break;
      case 'document':
        icon = Icons.description;
        color = Colors.green;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }

  Future<void> _showDeleteConfirmation(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus ${file.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _fileService.deleteFile(file.id);
        _loadFiles(refresh: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickAndUploadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari file...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadFiles(refresh: true);
              },
            ),
          ),
          Expanded(
            child:
                _files.isEmpty && !_isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64.w,
                            color: theme.colorScheme.tertiary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Tidak ada file',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _files.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _files.length) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: const CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildFileItem(_files[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
