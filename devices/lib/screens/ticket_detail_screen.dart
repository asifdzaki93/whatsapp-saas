import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ticket.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../widgets/message_bubble.dart';
import '../models/user.dart' as user_model;
import '../models/queue.dart' as queue_model;
import '../services/ticket_service.dart';
import '../models/whatsapp.dart' as whatsapp_model;
import '../models/attachment.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageService = MessageService();
  final _ticketService = TicketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _scheduleMessageController = TextEditingController();
  final _searchUserController = TextEditingController();
  List<Message> _messages = [];
  List<user_model.User> _searchResults = [];
  List<queue_model.Queue> _queues = [];
  bool _isLoading = false;
  bool _isLoadingQueues = false;
  bool _isSearchingUsers = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  DateTime? _selectedDate;
  user_model.User? _selectedUser;
  queue_model.Queue? _selectedQueue;
  List<whatsapp_model.Whatsapp> _whatsappConnections = [];
  bool _isLoadingWhatsapp = false;
  whatsapp_model.Whatsapp? _selectedWhatsapp;
  List<Attachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadQueues();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scheduleMessageController.dispose();
    _searchUserController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool refresh = false}) async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _messages = [];
      }
    });

    try {
      final messages = await _messageService.getMessages(
        widget.ticket.id,
        page: _currentPage,
      );

      setState(() {
        if (refresh) {
          _messages = messages;
        } else {
          final newMessages =
              messages
                  .where(
                    (message) =>
                        !_messages.any(
                          (existingMessage) => existingMessage.id == message.id,
                        ),
                  )
                  .toList();
          _messages.addAll(newMessages);
        }
        _hasMore = messages.length == 20;
        _currentPage++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMessages();
        _isLoadingMore = true;
      }
    }
  }

  Future<void> _loadQueues() async {
    setState(() {
      _isLoadingQueues = true;
    });

    try {
      final queues = await _ticketService.getQueues();
      setState(() {
        _queues = queues;
        _isLoadingQueues = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingQueues = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading queues: $e')));
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingUsers = false;
      });
      return;
    }

    setState(() {
      _isSearchingUsers = true;
    });

    try {
      final users = await _ticketService.searchUsers(query);
      setState(() {
        _searchResults = users;
        _isSearchingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        setState(() {
          _attachments.add(
            Attachment(
              name: file.name,
              path: file.path,
              type: file.mimeType ?? 'image/jpeg',
              size: 0, // Size will be calculated when uploading
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _scheduleMessage() async {
    print('\n=== Schedule Message UI Debug ===');

    if (_scheduleMessageController.text.trim().isEmpty) {
      print('Error: Message is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan masukkan pesan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      print('Error: No date selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih tanggal dan waktu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi tanggal tidak boleh di masa lalu
    if (_selectedDate!.isBefore(DateTime.now())) {
      print('Error: Selected date is in the past');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tanggal jadwal tidak boleh di masa lalu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Starting file upload process...');
      // Upload files first
      List<String> attachmentUrls = [];
      for (var attachment in _attachments) {
        try {
          print('Uploading file: ${attachment.name}');
          final url = await _ticketService.uploadFile(
            attachment.path,
            widget.ticket.id,
          );
          print('File uploaded successfully: $url');
          attachmentUrls.add(url);
        } catch (e) {
          print('Error uploading file: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengupload file ${attachment.name}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      print('Starting message scheduling...');
      // Schedule message with attachments
      await _ticketService.scheduleMessage(
        widget.ticket.id,
        _scheduleMessageController.text.trim(),
        _selectedDate!,
        attachments: attachmentUrls,
      );

      print('Message scheduled successfully');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesan berhasil dijadwalkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in _scheduleMessage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menjadwalkan pesan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== End Schedule Message UI Debug ===\n');
  }

  Future<void> _transferTicket() async {
    if (_selectedUser == null ||
        _selectedQueue == null ||
        _selectedWhatsapp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih pengguna, antrian, dan WhatsApp'),
        ),
      );
      return;
    }

    if (_selectedUser!.id == null ||
        _selectedQueue!.id == null ||
        _selectedWhatsapp!.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Data tidak valid')));
      return;
    }

    try {
      await _ticketService.transferTicket(
        widget.ticket.id,
        _selectedUser!.id!,
        _selectedQueue!.id!,
        _selectedWhatsapp!.id!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tiket berhasil ditransfer')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mentransfer tiket: $e')));
      }
    }
  }

  Future<void> _deleteTicket() async {
    try {
      await _ticketService.deleteTicketById(widget.ticket.id);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to tickets screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ticket deleted successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting ticket: $e')));
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    try {
      final newMessage = await _messageService.sendMessage(
        widget.ticket.id,
        message,
      );

      setState(() {
        _messages.insert(0, newMessage);
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hari ini';
    } else if (messageDate == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
    }
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          _getDateHeader(date),
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child:
                  widget.ticket.contact?.profilePicUrl != null
                      ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.ticket.contact!.profilePicUrl!,
                          width: 40.w,
                          height: 40.w,
                          fit: BoxFit.cover,
                          memCacheWidth: 80,
                          memCacheHeight: 80,
                          maxWidthDiskCache: 80,
                          maxHeightDiskCache: 80,
                          fadeInDuration: Duration(milliseconds: 200),
                          fadeOutDuration: Duration(milliseconds: 200),
                          imageBuilder:
                              (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          placeholder:
                              (context, url) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Text(
                                widget.ticket.contact?.name
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                        ),
                      )
                      : Text(
                        widget.ticket.contact?.name
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            '?',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ticket.contact?.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.ticket.status == 'pending'
                        ? 'Menunggu'
                        : widget.ticket.status == 'open'
                        ? 'Dilayani'
                        : 'Selesai',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'schedule':
                  _showScheduleDialog();
                  break;
                case 'transfer':
                  _showTransferDialog();
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'schedule',
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: theme.colorScheme.onSurface,
                        ),
                        SizedBox(width: 8.w),
                        Text('Jadwal'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(
                          Icons.transfer_within_a_station,
                          color: theme.colorScheme.onSurface,
                        ),
                        SizedBox(width: 8.w),
                        Text('Transfer'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: theme.colorScheme.onSurface),
                        SizedBox(width: 8.w),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadMessages(refresh: true);
              },
              child:
                  _isLoading && _messages.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: _messages.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final message = _messages[index];
                          final showDateHeader =
                              index == _messages.length - 1 ||
                              _messages[index + 1].createdAt?.year !=
                                  message.createdAt?.year ||
                              _messages[index + 1].createdAt?.month !=
                                  message.createdAt?.month ||
                              _messages[index + 1].createdAt?.day !=
                                  message.createdAt?.day;

                          return Column(
                            children: [
                              if (showDateHeader)
                                if (message.createdAt != null)
                                  _buildDateHeader(message.createdAt!),
                              MessageBubble(
                                message: message,
                                isMe: message.fromMe ?? false,
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                      // TODO: Implement emoji picker
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: () {
                      // TODO: Implement attachment picker
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt),
                    onPressed: () {
                      // TODO: Implement camera
                    },
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog() {
    _scheduleMessageController.clear();
    _selectedDate = null;
    _attachments = [];

    showDialog(
      context: context,
      builder:
          (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('id', 'ID'), Locale('en', 'US')],
            locale: Locale('id', 'ID'),
            theme: Theme.of(context),
            home: StatefulBuilder(
              builder:
                  (context, setState) => AlertDialog(
                    title: Text('Jadwal Pesan'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextField(
                              controller: _scheduleMessageController,
                              decoration: InputDecoration(
                                hintText:
                                    'Masukkan pesan yang akan dijadwalkan',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                              ),
                              maxLines: 3,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    Duration(days: 30),
                                  ),
                                  locale: Locale('id', 'ID'),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedDate = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16.sp,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pesan dijadwalkan pada:',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.tertiary,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          _selectedDate != null
                                              ? DateFormat(
                                                'EEEE, d MMMM y HH:mm',
                                                'id_ID',
                                              ).format(_selectedDate!)
                                              : 'Belum dipilih',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color:
                                                _selectedDate != null
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedDate != null)
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 16.sp,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedDate = null;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: InkWell(
                              onTap: _pickFile,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 16.sp,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lampiran:',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.tertiary,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        if (_attachments.isEmpty)
                                          Text(
                                            'Belum ada file dipilih',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          )
                                        else
                                          ..._attachments.asMap().entries.map((
                                            entry,
                                          ) {
                                            final index = entry.key;
                                            final attachment = entry.value;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 4.h,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      attachment.name,
                                                      style: TextStyle(
                                                        fontSize: 13.sp,
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.close,
                                                      size: 16.sp,
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .tertiary,
                                                    ),
                                                    onPressed:
                                                        () => _removeAttachment(
                                                          index,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: _scheduleMessage,
                        child: Text('Jadwalkan'),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showTransferDialog() {
    _searchUserController.clear();
    _selectedUser = null;
    _selectedQueue = null;
    _selectedWhatsapp = null;
    bool _isTransferring = false;
    List<user_model.User> _dialogSearchResults = [];
    bool _dialogIsSearchingUsers = false;

    // Load WhatsApp connections first
    _loadWhatsappConnections().then((connections) {
      setState(() {
        _whatsappConnections = connections;
        _isLoadingWhatsapp = false;
        // Set selected WhatsApp to the first connection if available
        if (connections.isNotEmpty) {
          _selectedWhatsapp = connections.first;
        }
      });
    });

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Transfer Tiket'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.ticket.status != 'open')
                          Container(
                            padding: EdgeInsets.all(8.w),
                            margin: EdgeInsets.only(bottom: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    'Tiket harus dalam status "Dilayani" untuk dapat ditransfer',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _searchUserController,
                                decoration: InputDecoration(
                                  hintText: 'Cari pengguna...',
                                  prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  suffixIcon:
                                      _dialogIsSearchingUsers
                                          ? Padding(
                                            padding: EdgeInsets.all(12.w),
                                            child: SizedBox(
                                              width: 16.w,
                                              height: 16.w,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.w,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                                onChanged: (value) async {
                                  if (value.isNotEmpty) {
                                    setDialogState(() {
                                      _dialogIsSearchingUsers = true;
                                    });
                                    try {
                                      final users = await _ticketService
                                          .searchUsers(value);
                                      setDialogState(() {
                                        _dialogSearchResults = users;
                                        _dialogIsSearchingUsers = false;
                                      });
                                    } catch (e) {
                                      setDialogState(() {
                                        _dialogIsSearchingUsers = false;
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error searching users: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    setDialogState(() {
                                      _dialogSearchResults = [];
                                    });
                                  }
                                },
                              ),
                              if (_dialogSearchResults.isNotEmpty)
                                Container(
                                  constraints: BoxConstraints(maxHeight: 200.h),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _dialogSearchResults.length,
                                    itemBuilder: (context, index) {
                                      final user = _dialogSearchResults[index];
                                      final isSelected =
                                          _selectedUser?.id == user.id;
                                      return InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            _selectedUser = user;
                                            _searchUserController.text =
                                                user.name;
                                            _dialogSearchResults = [];
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.1)
                                                    : null,
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16.r,
                                                backgroundColor: Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                    .withOpacity(0.1),
                                                child: Text(
                                                  user.name[0].toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user.name,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                        color:
                                                            isSelected
                                                                ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary
                                                                : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                      ),
                                                    ),
                                                    Text(
                                                      user.email,
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  size: 20.sp,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        if (_isLoadingWhatsapp)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8.h),
                                  Text('Memuat koneksi WhatsApp...'),
                                ],
                              ),
                            ),
                          )
                        else if (_whatsappConnections.isEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: Text(
                                'Tidak ada koneksi WhatsApp tersedia',
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButtonFormField<
                              whatsapp_model.Whatsapp
                            >(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Pilih Koneksi WhatsApp',
                                hintText: 'Pilih koneksi WhatsApp',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 12.h,
                                ),
                              ),
                              value: _selectedWhatsapp,
                              items:
                                  _whatsappConnections.map((whatsapp) {
                                    final isConnected =
                                        whatsapp.status == 'CONNECTED';
                                    return DropdownMenuItem(
                                      value: whatsapp,
                                      enabled: isConnected,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: 200.w,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6.w,
                                              height: 6.w,
                                              decoration: BoxDecoration(
                                                color:
                                                    isConnected
                                                        ? Colors.green
                                                        : whatsapp.status ==
                                                            'DISCONNECTED'
                                                        ? Colors.red
                                                        : Colors.orange,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Expanded(
                                              child: Text(
                                                whatsapp.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color:
                                                      isConnected
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .onSurface
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.5),
                                                ),
                                              ),
                                            ),
                                            if (!isConnected)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 4.w,
                                                ),
                                                child: Text(
                                                  whatsapp.status ==
                                                          'DISCONNECTED'
                                                      ? '(Terputus)'
                                                      : '(Menunggu)',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null &&
                                    value.status == 'CONNECTED') {
                                  setDialogState(() {
                                    _selectedWhatsapp = value;
                                  });
                                }
                              },
                            ),
                          ),
                        SizedBox(height: 16.h),
                        if (_isLoadingQueues)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8.h),
                                  Text('Memuat antrian...'),
                                ],
                              ),
                            ),
                          )
                        else if (_queues.isEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: Text('Tidak ada antrian tersedia'),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButtonFormField<queue_model.Queue>(
                              decoration: InputDecoration(
                                labelText: 'Transfer ke Antrian',
                                hintText: 'Pilih antrian',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                              ),
                              value: _selectedQueue,
                              items:
                                  _queues.map((queue) {
                                    return DropdownMenuItem(
                                      value: queue,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12.w,
                                            height: 12.w,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                int.parse(
                                                  queue.color.replaceAll(
                                                    '#',
                                                    '0xFF',
                                                  ),
                                                ),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(queue.name),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    _selectedQueue = value;
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          _isTransferring ? null : () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _isTransferring ||
                                  widget.ticket.status != 'open' ||
                                  _selectedUser == null ||
                                  _selectedQueue == null ||
                                  _selectedWhatsapp == null ||
                                  _selectedWhatsapp?.status != 'CONNECTED'
                              ? null
                              : () async {
                                setDialogState(() {
                                  _isTransferring = true;
                                });
                                try {
                                  await _transferTicket();
                                } finally {
                                  setDialogState(() {
                                    _isTransferring = false;
                                  });
                                }
                              },
                      child:
                          _isTransferring
                              ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                              : Text('Transfer'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<List<whatsapp_model.Whatsapp>> _loadWhatsappConnections() async {
    try {
      return await _ticketService.getWhatsappConnections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading WhatsApp connections: $e')),
        );
      }
      return [];
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hapus Tiket'),
            content: Text(
              'Apakah Anda yakin ingin menghapus tiket ini? Semua pesan terkait akan hilang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _deleteTicket,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Hapus'),
              ),
            ],
          ),
    );
  }
}
