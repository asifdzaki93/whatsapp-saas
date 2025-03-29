import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:ui' as ui;

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({Key? key, required this.message, required this.isMe})
    : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHighResLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: PhotoView(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                initialScale: PhotoViewComputedScale.contained,
                backgroundDecoration: BoxDecoration(color: Colors.black),
              ),
            ),
      ),
    );
  }

  Widget _buildMessageText(String text) {
    if (text.isEmpty) return SizedBox.shrink();

    List<TextSpan> spans = [];
    int currentIndex = 0;

    // Style dasar
    final baseStyle = TextStyle(
      fontSize: 14.sp,
      color: Colors.black87,
      height: 1.3,
      fontFamily: 'Noto Color Emoji',
    );

    // Regex untuk mendeteksi emoji
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F000}-\u{1F02F}\u{1F0A0}-\u{1F0FF}\u{1F100}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}]',
      unicode: true,
    );

    while (currentIndex < text.length) {
      final remainingText = text.substring(currentIndex);

      // Cek format WhatsApp
      if (remainingText.startsWith('*')) {
        final boldEnd = remainingText.indexOf('*', 1);
        if (boldEnd != -1) {
          spans.add(
            TextSpan(
              text: remainingText.substring(1, boldEnd),
              style: baseStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          );
          currentIndex += boldEnd + 1;
          continue;
        }
      }

      if (remainingText.startsWith('_')) {
        final italicEnd = remainingText.indexOf('_', 1);
        if (italicEnd != -1) {
          spans.add(
            TextSpan(
              text: remainingText.substring(1, italicEnd),
              style: baseStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          );
          currentIndex += italicEnd + 1;
          continue;
        }
      }

      if (remainingText.startsWith('~')) {
        final strikethroughEnd = remainingText.indexOf('~', 1);
        if (strikethroughEnd != -1) {
          spans.add(
            TextSpan(
              text: remainingText.substring(1, strikethroughEnd),
              style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
            ),
          );
          currentIndex += strikethroughEnd + 1;
          continue;
        }
      }

      if (remainingText.startsWith('`')) {
        final codeEnd = remainingText.indexOf('`', 1);
        if (codeEnd != -1) {
          spans.add(
            TextSpan(
              text: remainingText.substring(1, codeEnd),
              style: baseStyle.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[200],
                fontSize: 12.sp,
              ),
            ),
          );
          currentIndex += codeEnd + 1;
          continue;
        }
      }

      // Cek emoji
      final emojiMatch = emojiRegex.firstMatch(remainingText);
      if (emojiMatch != null && emojiMatch.start == 0) {
        spans.add(
          TextSpan(
            text: emojiMatch.group(0),
            style: baseStyle.copyWith(
              fontSize: 16.sp,
              fontFamily: 'Noto Color Emoji',
            ),
          ),
        );
        currentIndex += emojiMatch.end;
        continue;
      }

      // Jika tidak ada format, tambahkan teks biasa
      spans.add(TextSpan(text: remainingText[0], style: baseStyle));
      currentIndex++;
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.visible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final myBubbleColor = widget.isMe ? Color(0xFFDCF8C6) : Colors.white;
    final myTextColor = Colors.black87;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!widget.isMe && widget.message.fromMe == false)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h, left: 8.w),
                child: Text(
                  widget.message.contact?.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: myBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                  bottomLeft: Radius.circular(widget.isMe ? 8.r : 0),
                  bottomRight: Radius.circular(widget.isMe ? 0 : 8.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.mediaType != null) ...[
                    _buildMediaContent(context),
                    if (widget.message.body != null &&
                        widget.message.body!.isNotEmpty)
                      SizedBox(height: 8.h),
                  ],
                  if (widget.message.body != null &&
                      widget.message.body!.isNotEmpty)
                    _buildMessageText(widget.message.body!),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.message.createdAt != null)
                        Text(
                          DateFormat('HH:mm').format(widget.message.createdAt!),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.black54,
                          ),
                        ),
                      if (widget.isMe) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          widget.message.read ?? false
                              ? Icons.done_all
                              : Icons.done,
                          size: 16.sp,
                          color:
                              widget.message.read ?? false
                                  ? Colors.blue
                                  : Colors.black54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = widget.message.fromMe ?? false;

    if (widget.message.mediaType == null || widget.message.mediaType!.isEmpty) {
      return SizedBox.shrink();
    }

    switch (widget.message.mediaType!.toLowerCase()) {
      case 'image':
        return GestureDetector(
          onTap: () {
            if (widget.message.mediaUrl != null) {
              _showImagePreview(context, widget.message.mediaUrl!);
            }
          },
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Stack(
              children: [
                // Low resolution image (blur-up)
                if (widget.message.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.message.thumbnailUrl!,
                    width: 200.w,
                    height: 200.w,
                    fit: BoxFit.cover,
                    memCacheWidth: 100,
                    memCacheHeight: 100,
                    maxWidthDiskCache: 100,
                    maxHeightDiskCache: 100,
                    fadeInDuration: Duration(milliseconds: 0),
                    fadeOutDuration: Duration(milliseconds: 0),
                    imageBuilder:
                        (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                  ),
                // High resolution image
                CachedNetworkImage(
                  imageUrl: widget.message.mediaUrl ?? '',
                  width: 200.w,
                  height: 200.w,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  memCacheHeight: 800,
                  maxWidthDiskCache: 800,
                  maxHeightDiskCache: 800,
                  fadeInDuration: Duration(milliseconds: 300),
                  fadeOutDuration: Duration(milliseconds: 300),
                  placeholder:
                      (context, url) => Container(
                        width: 200.w,
                        height: 200.w,
                        color: Colors.grey[200],
                        child: Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
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
                      (context, url, error) => Container(
                        width: 200.w,
                        height: 200.w,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 32.w,
                        ),
                      ),
                  imageBuilder:
                      (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'video':
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200.w,
              height: 200.w,
              color: Colors.grey[200],
              child: Icon(Icons.videocam, color: Colors.grey[400], size: 32.w),
            ),
            if (widget.message.mediaDuration != null &&
                widget.message.mediaDuration!.isNotEmpty)
              Positioned(
                bottom: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    widget.message.mediaDuration!,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ),
              ),
          ],
        );
      case 'audio':
        return Container(
          width: 200.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(Icons.play_arrow, color: Colors.grey[600], size: 24.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.mediaDuration != null &&
                        widget.message.mediaDuration!.isNotEmpty)
                      Text(
                        widget.message.mediaDuration!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    SizedBox(height: 4.h),
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'document':
        return Container(
          width: 200.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                color: Colors.grey[600],
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.mediaName != null &&
                        widget.message.mediaName!.isNotEmpty)
                      Text(
                        widget.message.mediaName!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.message.mediaSize != null &&
                        widget.message.mediaSize!.isNotEmpty)
                      Text(
                        widget.message.mediaSize!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'location':
        return Container(
          width: 200.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[600], size: 24.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.locationName != null &&
                        widget.message.locationName!.isNotEmpty)
                      Text(
                        widget.message.locationName!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.message.latitude != null &&
                        widget.message.longitude != null)
                      Text(
                        '${widget.message.latitude}, ${widget.message.longitude}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'contact':
        return Container(
          width: 200.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              if (widget.message.contact?.profilePicUrl != null)
                CircleAvatar(
                  radius: 20.r,
                  backgroundImage: NetworkImage(
                    widget.message.contact!.profilePicUrl!,
                  ),
                )
              else
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    widget.message.contact?.name
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        '?',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.contact?.name != null &&
                        widget.message.contact!.name!.isNotEmpty)
                      Text(
                        widget.message.contact!.name!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.message.contact?.number != null &&
                        widget.message.contact!.number!.isNotEmpty)
                      Text(
                        widget.message.contact!.number!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }
}
